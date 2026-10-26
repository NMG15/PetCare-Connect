part of '../main.dart';

bool petCareHomeNeedsBlockingLoad({
  required bool hasSuccessfulLoad,
  required String? loadedUid,
  required String? currentUid,
}) => !hasSuccessfulLoad || loadedUid != currentUid || currentUid == null;

class PetCareHomeOncePerAccount {
  String? _activeUid;
  bool _completed = false;
  Future<void>? _inFlight;
  int _generation = 0;

  Future<void> run(String uid, Future<void> Function() task) {
    if (_activeUid != uid) {
      reset();
      _activeUid = uid;
    }
    if (_completed) return Future<void>.value();
    final running = _inFlight;
    if (running != null) return running;

    final generation = _generation;
    late final Future<void> attempt;
    attempt = Future<void>.sync(task)
        .then((_) {
          if (_generation == generation && _activeUid == uid) {
            _completed = true;
          }
        })
        .whenComplete(() {
          if (identical(_inFlight, attempt)) {
            _inFlight = null;
          }
        });
    _inFlight = attempt;
    return attempt;
  }

  void reset() {
    _generation++;
    _activeUid = null;
    _completed = false;
    _inFlight = null;
  }
}

Future<({List<Map<String, dynamic>> pets, bool isAdmin})>
petCareLoadHomeSummary({
  required Future<List<Map<String, dynamic>>> Function() loadPets,
  required Future<bool> Function() loadAdmin,
}) async {
  final results = await Future.wait<Object>([loadPets(), loadAdmin()]);
  return (
    pets: results[0] as List<Map<String, dynamic>>,
    isAdmin: results[1] as bool,
  );
}

class PetCareAgendaChangeFlag {
  bool _changed = false;
  bool get changed => _changed;
  void markChanged() {
    _changed = true;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> pets = [];
  bool loading = true;
  bool admin = false;
  bool _onlyPets = false;
  String? loadError;
  List<Map<String, dynamic>> _upcomingReminders = [];
  bool _upcomingLoading = false;
  final Set<String> _recordingUpcoming = <String>{};
  bool _homeLoadedSuccessfully = false;
  String? _homeLoadedUid;
  int _homeReloadGeneration = 0;
  final PetCareHomeOncePerAccount _profileWrite = PetCareHomeOncePerAccount();
  final PetCareHomeOncePerAccount _pushRegistration =
      PetCareHomeOncePerAccount();
  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final generation = ++_homeReloadGeneration;
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;
    final block = petCareHomeNeedsBlockingLoad(
      hasSuccessfulLoad: _homeLoadedSuccessfully,
      loadedUid: _homeLoadedUid,
      currentUid: currentUid,
    );
    if (mounted) {
      setState(() {
        if (block) {
          loading = true;
          pets = [];
          admin = false;
          _upcomingReminders = [];
        }
        loadError = null;
      });
    }
    try {
      if (currentUser != null) {
        try {
          await _profileWrite.run(
            currentUser.uid,
            () => CloudDb.instance.saveUserProfile(currentUser),
          );
        } on FirebaseException catch (e) {
          debugPrint('USER_PROFILE_REFRESH: ${e.code}');
        }
        if (!amazonBuild) {
          try {
            await _pushRegistration.run(
              currentUser.uid,
              () => PetCareCloudMessaging.instance.registerForCurrentUser(),
            );
          } catch (e) {
            debugPrint('FCM_NOT_AVAILABLE: ${e.runtimeType}');
          }
        }
      } else {
        _profileWrite.reset();
        _pushRegistration.reset();
      }
      final homeSummary = await petCareLoadHomeSummary(
        loadPets: CloudDb.instance.pets,
        loadAdmin: CloudDb.instance.isAdmin,
      );
      final result = homeSummary.pets;
      final isAdmin = homeSummary.isAdmin;

      if (!mounted ||
          generation != _homeReloadGeneration ||
          FirebaseAuth.instance.currentUser?.uid != currentUid) {
        return;
      }
      setState(() {
        pets = result;
        admin = isAdmin;
        loading = false;
        _homeLoadedUid = currentUid;
        _homeLoadedSuccessfully = true;
      });
      if (currentUser != null) {
        await _loadUpcomingReminders(result, currentUser.uid);
        if (!mounted ||
            generation != _homeReloadGeneration ||
            FirebaseAuth.instance.currentUser?.uid != currentUid) {
          return;
        }
        try {
          await PetCareAlerts.instance.syncForUser(currentUser.uid);
        } catch (e) {
          debugPrint('LOCAL_REMINDERS_SYNC: ${e.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('PETS_LOAD_FAILED: ${e.runtimeType}: $e');
      if (!mounted ||
          generation != _homeReloadGeneration ||
          FirebaseAuth.instance.currentUser?.uid != currentUid) {
        return;
      }
      if (block) {
        setState(() {
          loadError =
              'No pudimos cargar tus mascotas. Revisa internet y vuelve a intentarlo.';
          loading = false;
        });
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar. Intenta de nuevo.'),
          ),
        );
      }
    }
  }

  Future<void> _loadUpcomingReminders(
    List<Map<String, dynamic>> currentPets,
    String uid,
  ) async {
    if (mounted) setState(() => _upcomingLoading = true);
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now();
    try {
      for (final pet in currentPets) {
        final id = (pet['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('pets')
                .doc(id)
                .collection('reminders')
                .get();
        final hiddenIds =
            (pet['hiddenCareIds'] as List?)
                ?.map((value) => value.toString())
                .toSet() ??
            <String>{};
        for (final document in snapshot.docs) {
          final reminder = document.data();
          if (hiddenIds.contains((reminder['careId'] ?? '').toString())) {
            continue;
          }
          final next = nextPetReminder(reminder, now);
          if (next == null) continue;
          rows.add({
            'pet': pet,
            'care': (reminder['careLabel'] ?? 'Cuidado').toString(),
            'careId': (reminder['careId'] ?? '').toString(),
            'reminderId': document.id,
            'at': next,
          });
        }
      }
      rows.sort((a, b) => (a['at'] as DateTime).compareTo(b['at'] as DateTime));
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        setState(() => _upcomingReminders = rows.take(6).toList());
      }
    } catch (e) {
      debugPrint('DASHBOARD_REMINDERS: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _upcomingLoading = false);
    }
  }

  Future<void> _recordUpcomingCare(Map<String, dynamic> entry) async {
    final pet = entry['pet'] as Map<String, dynamic>;
    final petId = (pet['id'] ?? '').toString();
    final careId = (entry['careId'] ?? '').toString();
    final reminderId = (entry['reminderId'] ?? '').toString();
    if (petId.isEmpty || careId.isEmpty || reminderId.isEmpty) return;
    final id = '$petId|$reminderId';
    if (_recordingUpcoming.contains(id)) return;
    setState(() => _recordingUpcoming.add(id));
    try {
      final recordId = await CloudDb.instance.addCare(petId, {
        'id': careId,
        'label': entry['care'].toString(),
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cuidado registrado para ${pet['name']}. El horario continúa activo.',
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              try {
                await CloudDb.instance.deleteCareRecord(petId, recordId);
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo deshacer el registro.'),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo registrar el cuidado. Revisa tu conexión.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _recordingUpcoming.remove(id));
    }
  }

  Future<void> add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetEditor()),
    );
    await reload();
  }

  Future<void> _openAgenda() async {
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero registra una mascota para crear recordatorios.',
          ),
        ),
      );
      return;
    }
    if (pets.length == 1) {
      await _openPetAgenda(pets.first);
      return;
    }

    final agendaChanges = PetCareAgendaChangeFlag();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => AllPetsAgendaPage(
              pets: pets,
              onScheduleChanged: agendaChanges.markChanged,
            ),
      ),
    );
    if (mounted && agendaChanges.changed) await reload();
  }

  Future<void> _openPetAgenda(Map<String, dynamic> selected) async {
    if (!mounted) return;
    final agendaChanges = PetCareAgendaChangeFlag();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => PetRemindersPage(
              petId: selected['id'].toString(),
              petName: (selected['name'] ?? 'Mascota').toString(),
              species: (selected['species'] ?? '').toString(),
              onScheduleChanged: agendaChanges.markChanged,
            ),
      ),
    );
    if (mounted && agendaChanges.changed) await reload();
  }

  void _onTabSelected(int index) {
    if (index <= 1) {
      setState(() => _onlyPets = index == 1);
    } else if (index == 2) {
      _openAgenda();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()),
      );
    }
  }

  Future<void> delete(Map<String, dynamic> pet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text('¿Eliminar mascota?'),
            content: Text(
              'Se eliminarán ${pet['name']}, sus cuidados y sus recordatorios. Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(c).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(c, true),
                child: Text('Eliminar'),
              ),
            ],
          ),
    );
    if (ok == true) {
      try {
        await CloudDb.instance.deletePet(pet['id'].toString());
      } catch (e) {
        debugPrint('PET_DELETE_ERROR: ${e.runtimeType}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo completar la eliminación. Algunos registros podrían haberse eliminado. Actualiza la lista antes de reintentar.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mascota eliminada correctamente.')),
      );

      await reload();
    }
  }

  Future<void> _showPetActions(Map<String, dynamic> pet) async {
    final colors = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder:
          (sheetContext) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.viewPaddingOf(sheetContext).bottom + 50,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.70,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
                      child: Row(
                        children: [
                          Icon(Icons.pets_rounded, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (pet['name'] ?? 'Mi mascota').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.edit_outlined, color: colors.primary),
                      title: const Text('Editar mascota'),
                      subtitle: const Text('Actualizar sus datos y fotografía'),
                      onTap: () => Navigator.pop(sheetContext, 'edit'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: colors.primary,
                      ),
                      title: const Text('Horarios y recordatorios'),
                      subtitle: const Text('Gestionar los avisos de cuidado'),
                      onTap: () => Navigator.pop(sheetContext, 'reminders'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.history_outlined,
                        color: colors.primary,
                      ),
                      title: const Text('Historial de cuidados'),
                      subtitle: const Text('Consultar sus registros'),
                      onTap: () => Navigator.pop(sheetContext, 'history'),
                    ),
                    const Divider(height: 16),
                    ListTile(
                      leading: Icon(Icons.delete_outline, color: colors.error),
                      title: Text(
                        'Eliminar mascota',
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => Navigator.pop(sheetContext, 'delete'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
    if (!mounted || action == null) return;
    final petId = pet['id'].toString();
    final petName = (pet['name'] ?? 'Mascota').toString();
    final species = (pet['species'] ?? '').toString();
    if (action == 'delete') {
      await delete(pet);
    } else if (action == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PetEditor(existing: pet)),
      );
      if (mounted) await reload();
    } else if (action == 'reminders') {
      final agendaChanges = PetCareAgendaChangeFlag();
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder:
              (_) => PetRemindersPage(
                petId: petId,
                petName: petName,
                species: species,
                onScheduleChanged: agendaChanges.markChanged,
              ),
        ),
      );
      if (mounted && agendaChanges.changed) await reload();
    } else if (action == 'history') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetHistoryPage(petId: petId, petName: petName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'PetCare Connect',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: adaptiveInk(context),
        ),
      ),
      actions: [
        if (admin)
          IconButton(
            tooltip: 'Panel de administrador',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                ),
            icon: Icon(Icons.admin_panel_settings_outlined),
          ),
        PopupMenuButton<String>(
          tooltip: 'Mi cuenta y ajustes',
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(minWidth: 190, maxWidth: 230),
          icon: const PetCareProfileAvatar(radius: 17),
          onSelected: (value) async {
            if (value == 'settings') {
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppearanceSettingsPage(),
                ),
              );
              if (mounted) setState(() {});
            } else if (value == 'logout') {
              if (!amazonBuild) {
                await PetCareCloudMessaging.instance.unregisterCurrentUser();
              }
              await PetCareAlerts.instance.cancelAll();
              await FirebaseAuth.instance.signOut();
              _profileWrite.reset();
              _pushRegistration.reset();
            }
          },
          itemBuilder:
              (_) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 21),
                      SizedBox(width: 10),
                      Text('Mi cuenta y apariencia'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 21),
                      SizedBox(width: 10),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    ),
    bottomNavigationBar: PetCareBottomNav(
      selected: _onlyPets ? 1 : 0,
      onSelected: _onTabSelected,
    ),
    body:
        loading
            ? Center(child: CircularProgressIndicator())
            : loadError != null
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 14),
                    Text(loadError!, textAlign: TextAlign.center),
                    SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: reload,
                      icon: Icon(Icons.refresh),
                      label: Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
            : RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                children: [
                  if (!_onlyPets) ...[
                    PetCareSignatureHero(
                      eyebrow: homeGreeting(
                        FirebaseAuth.instance.currentUser?.displayName,
                      ),
                      title: 'Pequeños cuidados.\nGrandes momentos.',
                      subtitle:
                          'Lleva su bienestar al día, de forma sencilla y con cariño.',
                      icon: Icons.pets_rounded,
                    ),
                    const SizedBox(height: 13),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.pets_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Mis mascotas',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${pets.length}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PetCareSectionTitle(
                      title: 'Accesos rápidos',
                      caption: 'Lo que necesitas, siempre a mano.',
                    ),
                    PetCareActionTile(
                      title: 'Ver agenda y recordatorios',
                      subtitle: 'Consulta los horarios de tus mascotas',
                      icon: Icons.calendar_month_outlined,
                      onTap: _openAgenda,
                    ),
                    const SizedBox(height: 16),
                    const PetCareSectionTitle(
                      title: 'Hoy y próximos cuidados',
                      caption: 'Recordatorios pendientes de tus mascotas.',
                    ),
                    const SizedBox(height: 8),
                    if (_upcomingLoading)
                      const LinearProgressIndicator()
                    else if (_upcomingReminders.isEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available_outlined),
                          title: const Text('Sin horarios próximos'),
                          subtitle: const Text(
                            'Crea un horario en Agenda para verlo aquí.',
                          ),
                          onTap: _openAgenda,
                        ),
                      )
                    else
                      ..._upcomingReminders.map((entry) {
                        final pet = entry['pet'] as Map<String, dynamic>;
                        final next = entry['at'] as DateTime;
                        final dayLabel =
                            dateKey(next) == dateKey(DateTime.now())
                                ? 'Hoy'
                                : 'Próximo día';
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            title: Text(entry['care'].toString()),
                            subtitle: Text(
                              '${pet['name']} · $dayLabel ${next.day}/${next.month} · ${petTimeAmPm(next.hour, next.minute)}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Registrar cuidado realizado',
                              icon: Icon(
                                Icons.check_circle_outline_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed:
                                  (entry['careId'] ?? '').toString().isEmpty ||
                                          _recordingUpcoming.contains(
                                            '${pet['id']}|${entry['reminderId']}',
                                          )
                                      ? null
                                      : () => _recordUpcomingCare(entry),
                            ),
                            onTap: () => _openPetAgenda(pet),
                          ),
                        );
                      }),
                  ] else ...[
                    const PetCarePageIntro(
                      eyebrow: 'Tu pequeña gran familia',
                      title: 'Mis mascotas',
                      subtitle: 'Cada historia empieza con un nombre.',
                      icon: Icons.pets_rounded,
                    ),
                  ],
                  if (FirebaseAuth.instance.currentUser?.emailVerified ==
                          false &&
                      FirebaseAuth.instance.currentUser?.providerData.any(
                            (provider) => provider.providerId == 'password',
                          ) ==
                          true)
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: adaptiveInk(context),
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Confirma tu correo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: adaptiveInk(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 7),
                            Text(
                              'Te enviamos un enlace de verificación. Revisa tu bandeja y spam.',
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseAuth.instance.currentUser
                                          ?.sendEmailVerification();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Correo enviado. Revisa tu bandeja y spam.',
                                          ),
                                        ),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No se pudo reenviar el correo: ${e.message ?? e.code}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('Reenviar correo'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.currentUser
                                        ?.reload();
                                    if (mounted) setState(() {});
                                  },
                                  child: Text('Ya verifiqué'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 18),
                  PetCareSectionTitle(
                    title:
                        _onlyPets
                            ? 'Tus compañeros'
                            : 'Vista rápida de tu familia',
                    caption:
                        '${pets.length} ${pets.length == 1 ? 'mascota registrada' : 'mascotas registradas'}',
                    trailing:
                        pets.isEmpty
                            ? null
                            : TextButton(
                              onPressed: add,
                              child: const Text('Agregar +'),
                            ),
                  ),
                  SizedBox(height: 14),
                  if (pets.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pets,
                              size: 58,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Aún no tienes mascotas',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Agrega una mascota y personaliza su perfil.',
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            FilledButton(
                              onPressed: add,
                              child: Text('Agregar mi primera mascota'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...(_onlyPets ? pets : pets.take(2)).map(
                      (pet) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        PetDetail(petId: pet['id'].toString()),
                              ),
                            );
                            await reload();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 38,
                                  backgroundColor: adaptivePale(context),
                                  backgroundImage: petPhoto(pet),
                                  child:
                                      petPhoto(pet) == null
                                          ? Text(
                                            emojiFor(pet['species']),
                                            style: TextStyle(fontSize: 32),
                                          )
                                          : null,
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${pet['name']}',
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: adaptiveInk(context),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        petSpeciesDescription(pet),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: adaptiveMuted(context),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Ver perfil y cuidados',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Opciones de ${pet['name']}',
                                  onPressed: () => _showPetActions(pet),
                                  icon: const Icon(Icons.more_vert_rounded),
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
  );
}

class PetEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const PetEditor({super.key, this.existing});
  @override
  State<PetEditor> createState() => _PetEditorState();
}

class _PetEditorState extends State<PetEditor> {
  late String species, breed, sex;
  String? image;
  bool saving = false;
  bool customCoat = false;
  final name = TextEditingController(),
      age = TextEditingController(),
      weight = TextEditingController(),
      color = TextEditingController(),
      coat = TextEditingController();
  final customSpecies = TextEditingController();
  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    customSpecies.text = (old?['customSpecies'] ?? '').toString();
    species = (old?['species'] ?? 'Perro').toString();
    if (!speciesCatalog.containsKey(species)) species = 'Perro';
    breed = (old?['breed'] ?? 'Raza sin especificar').toString();
    sex = (old?['sex'] ?? 'No especificado').toString();
    image = old?['imagePath']?.toString();
    name.text = (old?['name'] ?? '').toString();
    age.text = (old?['age'] ?? '').toString();
    weight.text = (old?['weight'] ?? '').toString();
    color.text = (old?['color'] ?? '').toString();
    coat.text = (old?['coat'] ?? '').toString();
    customCoat =
        coat.text.isNotEmpty && !petCoatOptions(species).contains(coat.text);
  }

  @override
  void dispose() {
    for (final c in [name, age, weight, color, coat, customSpecies]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> choosePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1100,
      );
      if (file == null) return;
      final originalBytes = await file.readAsBytes();
      if (!mounted) return;
      final adjustedBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  ProfilePhotoCropPage(imageBytes: originalBytes, forPet: true),
        ),
      );
      if (adjustedBytes == null || !mounted) return;
      final dir = await getApplicationDocumentsDirectory();
      final photos = Directory(p.join(dir.path, 'pet_photos'));
      await photos.create(recursive: true);
      final saved = File(
        p.join(photos.path, 'pet_${DateTime.now().microsecondsSinceEpoch}.png'),
      );
      await saved.writeAsBytes(adjustedBytes, flush: true);
      if (mounted) setState(() => image = saved.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo seleccionar la fotografía.')),
        );
      }
    }
  }

  Future<void> selectBreed() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BreedSelector(species: species, selected: breed),
    );
    if (chosen != null && mounted) setState(() => breed = chosen);
  }

  Future<void> save() async {
    final validation = validatePetData(
      name: name.text,
      age: age.text,
      weight: weight.text,
    );
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final customError = validateCustomSpecies(species, customSpecies.text);
    if (customError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(customError)));
      return;
    }
    setState(() => saving = true);
    try {
      final values = <String, dynamic>{
        'name': name.text.trim(),
        'species': species,
        'customSpecies':
            species == 'Otra especie' ? customSpecies.text.trim() : '',
        'breed': breed,
        'sex': sex,
        'age': age.text.trim(),
        'weight': weight.text.trim(),
        'color': color.text.trim(),
        'coat': coat.text.trim(),
        'imagePath': image ?? '',
      };
      if (widget.existing == null) {
        await CloudDb.instance.addPet(values);
      } else {
        await CloudDb.instance.updatePet(
          widget.existing!['id'].toString(),
          values,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la mascota.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Nueva mascota' : 'Editar mascota'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      children: [
        PetCarePageIntro(
          eyebrow: 'Un lugar para cada historia',
          title:
              widget.existing == null ? 'Nueva mascota' : 'Actualizar perfil',
          subtitle: 'Guarda los detalles que hacen única a tu mascota.',
          icon: Icons.pets_outlined,
        ),
        Center(
          child: InkWell(
            onTap: choosePhoto,
            borderRadius: BorderRadius.circular(70),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: adaptivePale(context),
                  backgroundImage:
                      image != null && File(image!).existsSync()
                          ? FileImage(File(image!))
                          : null,
                  child:
                      image == null || !File(image!).existsSync()
                          ? Text(
                            emojiFor(species),
                            style: TextStyle(fontSize: 55),
                          )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.camera_alt_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 9),
        Center(
          child: Text(
            'Agregar o cambiar foto',
            style: TextStyle(color: adaptiveMuted(context)),
          ),
        ),
        SizedBox(height: 25),
        Text(
          'Datos principales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: adaptiveInk(context),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Nombre de la mascota',
          style: TextStyle(
            color: adaptiveMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Ej. Orejitas',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Especie',
          style: TextStyle(
            color: adaptiveMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          menuMaxHeight: 300,
          isExpanded: true,
          initialValue: species,
          decoration: InputDecoration(prefixIcon: Icon(Icons.pets)),
          items:
              speciesCatalog.keys
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text('${emojiFor(v)}  $v'),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                species = v;
                breed = 'Raza sin especificar';
                coat.clear();
                customCoat = false;
              });
            }
          },
        ),
        if (species == 'Otra especie') ...[
          TextField(
            controller: customSpecies,
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: '¿Qué animal es?',
              hintText: 'Ej. mono, león, pantera u otro',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(height: 12),
        ListTile(
          tileColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text('Raza / categoría'),
          subtitle: Text(breed, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Icon(Icons.chevron_right),
          onTap: selectBreed,
        ),
        SizedBox(height: 12),
        Text(
          'Sexo',
          style: TextStyle(
            color: adaptiveMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          menuMaxHeight: 300,
          isExpanded: true,
          initialValue:
              ['Macho', 'Hembra', 'No especificado'].contains(sex)
                  ? sex
                  : 'No especificado',
          decoration: const InputDecoration(),
          items:
              [
                'Macho',
                'Hembra',
                'No especificado',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => sex = v);
          },
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edad', style: TextStyle(color: adaptiveMuted(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: age,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Ej. 2',
                      suffixText: age.text.trim() == '1' ? 'año' : 'años',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peso', style: TextStyle(color: adaptiveMuted(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Ej. 15',
                      suffixText: 'kg',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.palette_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('Colores'),
            subtitle: Text(
              color.text.trim().isEmpty
                  ? 'Selecciona uno o varios colores'
                  : color.text.trim(),
            ),
            trailing: Icon(Icons.expand_more),
            onTap: () async {
              final value = await choosePetColors(
                context,
                color.text,
                species: species,
              );
              if (value != null && mounted) setState(() => color.text = value);
            },
          ),
        ),
        SizedBox(height: 12),
        Text(
          species == 'Ave'
              ? 'Plumaje'
              : (species == 'Pez' ||
                  species == 'Tortuga' ||
                  species == 'Iguana' ||
                  species == 'Erizo')
              ? 'Características'
              : 'Pelaje',
          style: TextStyle(
            color: adaptiveMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          menuMaxHeight: 300,
          isExpanded: true,
          key: ValueKey('pelaje-$species'),
          initialValue:
              customCoat
                  ? 'Otro (especificar)'
                  : petCoatOptions(species).contains(coat.text)
                  ? coat.text
                  : null,
          hint: Text(
            species == 'Ave'
                ? 'Selecciona el plumaje'
                : (species == 'Pez' ||
                    species == 'Tortuga' ||
                    species == 'Iguana' ||
                    species == 'Erizo')
                ? 'Selecciona una característica'
                : 'Selecciona el pelaje',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerLow,
          iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.tune)),
          items:
              [...petCoatOptions(species), 'Otro (especificar)']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              customCoat = value == 'Otro (especificar)';
              coat.text = customCoat ? '' : value;
            });
          },
        ),
        if (customCoat) ...[
          SizedBox(height: 10),
          TextField(
            controller: coat,
            decoration: InputDecoration(
              labelText: 'Describe la característica',
              hintText: 'Ej. corto y rizado',
            ),
          ),
        ],
        const SizedBox(height: 26),
      ],
    ),
    bottomNavigationBar: petCareActionFooter(
      context,
      FilledButton.icon(
        onPressed: saving ? null : save,
        icon: const Icon(Icons.check),
        label: Text(
          saving
              ? 'Guardando...'
              : widget.existing == null
              ? 'Guardar mascota'
              : 'Guardar cambios',
        ),
      ),
    ),
  );
}

class BreedSelector extends StatefulWidget {
  final String species, selected;
  const BreedSelector({
    super.key,
    required this.species,
    required this.selected,
  });
  @override
  State<BreedSelector> createState() => _BreedSelectorState();
}

class _BreedSelectorState extends State<BreedSelector> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final list =
        speciesCatalog[widget.species]!
            .where((v) => v.toLowerCase().contains(search.trim().toLowerCase()))
            .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Razas y categorías · ${widget.species}',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: adaptiveInk(context),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar raza o categoría',
                      ),
                      onChanged: (v) => setState(() => search = v),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child:
                    list.isEmpty
                        ? const Center(
                          child: Text(
                            'No encontramos esa raza. Borra el filtro y elige «Raza sin especificar».',
                          ),
                        )
                        : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final value = list[i];
                            return ListTile(
                              title: Text(value),
                              trailing:
                                  value == widget.selected
                                      ? Icon(
                                        Icons.check_circle,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      )
                                      : null,
                              onTap: () => Navigator.pop(context, value),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetDetail extends StatefulWidget {
  final String petId;
  const PetDetail({super.key, required this.petId});
  @override
  State<PetDetail> createState() => _PetDetailState();
}

class _PetDetailState extends State<PetDetail> {
  Map<String, dynamic>? pet;
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> careTypes = [];
  final Set<String> _savingCareIds = <String>{};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final current = await CloudDb.instance.pet(widget.petId);
    final entries = await CloudDb.instance.care(widget.petId);
    final types =
        current == null
            ? <Map<String, dynamic>>[]
            : await CloudDb.instance.careCatalogForPet(
              (current['species'] ?? '').toString(),
              current,
            );
    final hidden =
        (current?['hiddenCareIds'] as List?)
            ?.map((value) => value.toString())
            .toSet() ??
        <String>{};
    final visible =
        types
            .where((type) => !hidden.contains((type['id'] ?? '').toString()))
            .toList();

    if (mounted) {
      setState(() {
        pet = current;
        history = entries;
        careTypes = visible;
      });
    }
  }

  Future<void> mark(Map<String, dynamic> careType) async {
    final id = (careType['id'] ?? '').toString();
    if (id.isEmpty || _savingCareIds.contains(id)) return;
    setState(() => _savingCareIds.add(id));
    try {
      final recordId = await CloudDb.instance.addCare(widget.petId, careType);
      await load();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('«${careTypeLabel(careType)}» registrado.'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () async {
                try {
                  await CloudDb.instance.deleteCareRecord(
                    widget.petId,
                    recordId,
                  );
                  if (mounted) await load();
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No se pudo deshacer. Revisa tu conexión.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se guardó el cuidado. Revisa tu conexión.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingCareIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = pet;
    if (current == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = history.where(isToday).toList();
    final completed =
        careTypes.where((type) {
          final id = (type['id'] ?? '').toString();
          return today.any((row) => (row['type'] ?? '').toString() == id);
        }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${current['name']}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Editar mascota',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PetEditor(existing: current)),
              );
              await load();
            },
            icon: Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      Theme.of(context).brightness == Brightness.dark
                          ? const [Color(0xFF26292D), Color(0xFF16191C)]
                          : const [Color(0xFF174F3B), Color(0xFF0B3729)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Text(
                    'SU PERFIL',
                    style: TextStyle(
                      color: Color(0xFF47E6A1),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white24,
                    backgroundImage: petPhoto(current),
                    child:
                        petPhoto(current) == null
                            ? Text(
                              emojiFor(current['species']),
                              style: TextStyle(fontSize: 47),
                            )
                            : null,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '${current['name']}',
                    style: TextStyle(
                      fontSize: 27,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    petSpeciesDescription(current),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuidados de hoy',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: adaptiveInk(context),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$completed de ${careTypes.length} tipos de cuidado registrados',
                      style: TextStyle(color: adaptiveMuted(context)),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value:
                          careTypes.isEmpty ? 0 : completed / careTypes.length,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(12),
                      backgroundColor: adaptivePale(context),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Su rutina de cuidados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: adaptiveInk(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Horarios, historial y cuidados a su medida.',
                      style: TextStyle(
                        fontSize: 12,
                        color: adaptiveMuted(context),
                      ),
                    ),
                    const SizedBox(height: 13),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PetRemindersPage(
                                  petId: widget.petId,
                                  petName:
                                      (current['name'] ?? 'tu mascota')
                                          .toString(),
                                  species:
                                      (current['species'] ?? '').toString(),
                                ),
                          ),
                        );
                        await load();
                      },
                      icon: Icon(Icons.notifications_active_outlined),
                      label: Text('Horarios y recordatorios'),
                    ),
                    SizedBox(height: 7),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PetHistoryPage(
                                  petId: widget.petId,
                                  petName:
                                      (current['name'] ?? 'Mascota').toString(),
                                ),
                          ),
                        );
                        await load();
                      },
                      icon: Icon(Icons.calendar_month_outlined),
                      label: Text('Ver historial de cuidados'),
                    ),
                    SizedBox(height: 7),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PetCareVisibilityPage(
                                  petId: widget.petId,
                                  petName:
                                      (current['name'] ?? 'Mascota').toString(),
                                  species:
                                      (current['species'] ?? '').toString(),
                                ),
                          ),
                        );
                        await load();
                      },
                      icon: Icon(Icons.tune_outlined),
                      label: Text('Personalizar cuidados'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 12),
              child: Text(
                'Marca cada cuidado cuando lo realices. El conteo comienza de nuevo cada día; '
                'los avisos solo se envían si configuras un horario.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: adaptiveMuted(context),
                ),
              ),
            ),
            if (careTypes.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay tipos de cuidado activos para esta especie.',
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        careTypes.map((type) {
                          final id = (type['id'] ?? '').toString();
                          final countToday =
                              today
                                  .where(
                                    (row) =>
                                        (row['type'] ?? '').toString() == id,
                                  )
                                  .length;
                          return SizedBox(
                            width: width,
                            child: PetCareTodayTile(
                              care: type,
                              countToday: countToday,
                              saving: _savingCareIds.contains(id),
                              onTap: () => mark(type),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            SizedBox(height: 22),
            Text(
              'Información',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: adaptiveInk(context),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    detailRow('Sexo', current['sex']),
                    detailRow('Edad', petAgeLabel(current['age'])),
                    detailRow(
                      'Peso',
                      (current['weight'] ?? '').toString().isEmpty
                          ? ''
                          : '${current['weight']} kg',
                    ),
                    detailRow('Color', current['color']),
                    detailRow(
                      current['species'] == 'Ave'
                          ? 'Plumaje'
                          : current['species'] == 'Pez' ||
                              current['species'] == 'Tortuga'
                          ? 'Características'
                          : 'Pelaje',
                      current['coat'],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 22),
            Text(
              'Últimos cuidados registrados',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: adaptiveInk(context),
              ),
            ),
            SizedBox(height: 8),
            if (history.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Todavía no hay cuidados registrados.'),
                ),
              )
            else
              ...history.take(30).map((entry) {
                final date = careDate(entry);
                final dateText =
                    date == null
                        ? 'Registro anterior'
                        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                final note = (entry['note'] ?? '').toString().trim();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: adaptivePale(context),
                      child: Icon(
                        careEntryIcon(entry, careTypes),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(careEntryLabel(entry, careTypes)),
                    subtitle: Text(
                      note.isEmpty
                          ? '$dateText · ${entry['time']}'
                          : '$dateText · ${entry['time']}\n$note',
                    ),
                    isThreeLine: note.isNotEmpty,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String title, dynamic value) {
    final valueText = (value ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: adaptiveMuted(context))),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              valueText.isEmpty ? 'No registrado' : valueText,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime petCareAgendaDateForMonth(DateTime selected, DateTime month) {
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final day = selected.day <= lastDay ? selected.day : lastDay;
  return DateTime(month.year, month.month, day);
}

int petCareAgendaCountForDate(
  List<Map<String, dynamic>> reminders,
  DateTime date,
  String? petFilter,
) {
  return reminders.where((row) {
    final pet = row['pet'];
    if (pet is! Map) {
      return false;
    }
    if (petFilter != null && pet['id'].toString() != petFilter) {
      return false;
    }
    return reminderAppliesOnDate(row, date);
  }).length;
}

Map<int, int> petCareAgendaNextMarkersInMonth(
  List<Map<String, dynamic>> reminders,
  DateTime visibleDate,
  String? petFilter,
  DateTime now,
) {
  final monthStart = DateTime(visibleDate.year, visibleDate.month, 1);
  final monthEnd = DateTime(visibleDate.year, visibleDate.month + 1, 1);
  if (!monthEnd.isAfter(now)) {
    return <int, int>{};
  }
  final start =
      monthStart.isAfter(now)
          ? monthStart.subtract(const Duration(microseconds: 1))
          : now;
  final counts = <int, int>{};
  for (final row in reminders) {
    final pet = row['pet'];
    if (pet is! Map) {
      continue;
    }
    if (petFilter != null && pet['id'].toString() != petFilter) {
      continue;
    }
    final next = nextPetReminder(row, start);
    if (next == null ||
        next.year != visibleDate.year ||
        next.month != visibleDate.month) {
      continue;
    }
    counts.update(
      next.day,
      (totalPrevio) => totalPrevio + 1,
      ifAbsent: () => 1,
    );
  }
  return counts;
}

class PetCareAgendaMonthGrid extends StatelessWidget {
  const PetCareAgendaMonthGrid({
    super.key,
    required this.selectedDate,
    required this.reminders,
    required this.petFilter,
    required this.onDateChanged,
    this.nowOverride,
  });

  final DateTime selectedDate;
  final List<Map<String, dynamic>> reminders;
  final String? petFilter;
  final ValueChanged<DateTime> onDateChanged;

  final DateTime? nowOverride;

  static const List<String> _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const List<String> _weekdays = [
    'Lu',
    'Ma',
    'Mi',
    'Ju',
    'Vi',
    'Sa',
    'Do',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final offset = first.weekday - DateTime.monday;
    final cells = ((offset + lastDay + 6) ~/ 7) * 7;
    final today = nowOverride ?? DateTime.now();
    final nextMarkers = petCareAgendaNextMarkersInMonth(
      reminders,
      selectedDate,
      petFilter,
      today,
    );
    final monthLabel = _months[selectedDate.month - 1];
    final totalForDay = petCareAgendaCountForDate(
      reminders,
      selectedDate,
      petFilter,
    );

    void moveMonth(int distance) {
      final target = DateTime(
        selectedDate.year,
        selectedDate.month + distance,
        1,
      );
      if (target.year < 2020 || target.year > 2100) {
        return;
      }
      onDateChanged(petCareAgendaDateForMonth(selectedDate, target));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => moveMonth(-1),
                ),
                Expanded(
                  child: Text(
                    '${monthLabel[0].toUpperCase()}${monthLabel.substring(1)} ${selectedDate.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => moveMonth(1),
                ),
              ],
            ),
            Row(
              children:
                  _weekdays
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final day = index - offset + 1;
                if (day < 1 || day > lastDay) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  day,
                );
                final markerCount = nextMarkers[day] ?? 0;
                final selected = day == selectedDate.day;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Dia $day, $markerCount proximos avisos indicados',
                  child: InkWell(
                    key: ValueKey(
                      'petcare-agenda-dia-${date.year}-${date.month}-$day',
                    ),
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onDateChanged(date),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? scheme.primary : null,
                            border:
                                isToday && !selected
                                    ? Border.all(color: scheme.primary)
                                    : null,
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color:
                                  selected
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 9,
                          child:
                              markerCount > 3
                                  ? Text(
                                    '$markerCount',
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  )
                                  : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      markerCount,
                                      (i) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        child: Container(
                                          key: ValueKey(
                                            'petcare-agenda-dot-${date.year}-${date.month}-$day-$i',
                                          ),
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 9),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Icon(Icons.circle, size: 9, color: scheme.primary),
                const Text(
                  'Puntos = siguiente aviso de cada horario; 4+ = numero',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '$totalForDay ${totalForDay == 1 ? "aviso" : "avisos"} el ${selectedDate.day}/${selectedDate.month}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Los horarios que se repiten siguen visibles al elegir otros dias.',
                style: TextStyle(fontSize: 11),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    () => onDateChanged(
                      DateTime(today.year, today.month, today.day),
                    ),
                icon: const Icon(Icons.today_outlined, size: 18),
                label: const Text('Ir a hoy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllPetsAgendaPage extends StatefulWidget {
  final List<Map<String, dynamic>> pets;
  final VoidCallback? onScheduleChanged;
  const AllPetsAgendaPage({
    super.key,
    required this.pets,
    this.onScheduleChanged,
  });

  @override
  State<AllPetsAgendaPage> createState() => _AllPetsAgendaPageState();
}

class _AllPetsAgendaPageState extends State<AllPetsAgendaPage> {
  DateTime selectedDate = DateTime.now();
  String? petFilter;
  List<Map<String, dynamic>> reminders = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('No hay sesión activa.');
      final lists = await Future.wait(
        widget.pets.map((pet) async {
          final petId = (pet['id'] ?? '').toString();
          if (petId.isEmpty) return <Map<String, dynamic>>[];
          final snap =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('pets')
                  .doc(petId)
                  .collection('reminders')
                  .get();
          return snap.docs
              .map(
                (doc) => <String, dynamic>{
                  'pet': pet,
                  'id': doc.id,
                  ...doc.data(),
                },
              )
              .toList();
        }),
      );
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        setState(() {
          reminders = lists.expand((list) => list).toList();
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudo cargar la agenda. Comprueba tu conexión.';
          loading = false;
        });
      }
    }
  }

  Future<void> _openPet(Map<String, dynamic> pet) async {
    final agendaChanges = PetCareAgendaChangeFlag();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => PetRemindersPage(
              petId: (pet['id'] ?? '').toString(),
              petName: (pet['name'] ?? 'Mascota').toString(),
              species: (pet['species'] ?? '').toString(),
              onScheduleChanged: agendaChanges.markChanged,
            ),
      ),
    );
    if (mounted && agendaChanges.changed) {
      widget.onScheduleChanged?.call();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown =
        reminders.where((row) {
            final pet = row['pet'] as Map<String, dynamic>;
            return (petFilter == null || pet['id'].toString() == petFilter) &&
                reminderAppliesOnDate(row, selectedDate);
          }).toList()
          ..sort((a, b) {
            final timeA =
                (a['hour'] as num).toInt() * 60 + (a['minute'] as num).toInt();
            final timeB =
                (b['hour'] as num).toInt() * 60 + (b['minute'] as num).toInt();
            return timeA.compareTo(timeB);
          });

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de avisos')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    const PetCarePageIntro(
                      eyebrow: 'Cuidados compartidos',
                      title: 'Tus avisos en calendario',
                      subtitle:
                          'Los puntos verdes marcan los dias con recordatorios; toca un dia para verlos.',
                      icon: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Todas'),
                            selected: petFilter == null,
                            onSelected: (_) => setState(() => petFilter = null),
                          ),
                          ...widget.pets.map(
                            (pet) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(
                                  (pet['name'] ?? 'Mascota').toString(),
                                ),
                                selected: petFilter == pet['id'].toString(),
                                onSelected:
                                    (_) => setState(
                                      () => petFilter = pet['id'].toString(),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 2, 4, 8),
                      child: Text(
                        'Los avisos se repiten segun los dias configurados. '
                        'Las actividades realizadas estan en el Historial.',
                      ),
                    ),
                    PetCareAgendaMonthGrid(
                      selectedDate: selectedDate,
                      reminders: reminders,
                      petFilter: petFilter,
                      onDateChanged:
                          (date) => setState(() => selectedDate = date),
                    ),
                    const SizedBox(height: 16),
                    PetCareSectionTitle(
                      title:
                          'Avisos del ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      caption:
                          petFilter == null
                              ? 'Todas tus mascotas'
                              : 'Mascota seleccionada',
                    ),
                    const SizedBox(height: 8),
                    if (shown.isEmpty)
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.event_available_outlined),
                          title: Text(
                            'No hay AVISOS programados para esta fecha.',
                          ),
                          subtitle: Text(
                            'La agenda solo muestra recordatorios configurados. '
                            'Los cuidados ya realizados aparecen en el Historial. '
                            'Para crear uno, abre Horarios y recordatorios de una mascota.',
                          ),
                        ),
                      ),
                    ...shown.map((row) {
                      final pet = row['pet'] as Map<String, dynamic>;
                      final time = TimeOfDay(
                        hour: (row['hour'] as num).toInt(),
                        minute: (row['minute'] as num).toInt(),
                      );
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          title: Text(
                            (row['careLabel'] ?? 'Cuidado').toString(),
                          ),
                          subtitle: Text(
                            '${pet['name']} · ${petTimeAmPm(time.hour, time.minute)}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openPet(pet),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.tune_rounded),
                        title: const Text('Administrar horarios'),
                        subtitle: const Text('Crear o editar por mascota'),
                        children:
                            widget.pets
                                .map(
                                  (pet) => ListTile(
                                    leading: const Icon(Icons.pets_outlined),
                                    title: Text(
                                      (pet['name'] ?? 'Mascota').toString(),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () => _openPet(pet),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
