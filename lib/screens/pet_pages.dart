// PetCare Connect: módulo del mismo paquete Dart; comparte los componentes internos.
part of '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> pets = [];
  bool loading = true;
  bool admin = false;
  String? loadError;
  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (mounted) setState(() { loading = true; loadError = null; });
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await CloudDb.instance.saveUserProfile(currentUser);
        } on FirebaseException catch (e) {
          debugPrint('USER_PROFILE_REFRESH: ${e.code}');
        }
        if (!amazonBuild) {
          try {
            await PetCareCloudMessaging.instance.registerForCurrentUser();
          } catch (e) {
            debugPrint('FCM_NOT_AVAILABLE: ${e.runtimeType}');
          }
        }
      }
      final result = await CloudDb.instance.pets();
      final isAdmin = await CloudDb.instance.isAdmin();
      if (mounted) {
        setState(() { pets = result; admin = isAdmin; loading = false; });
      }
      if (currentUser != null) {
        try {
          await PetCareAlerts.instance.syncForUser(currentUser.uid);
        } catch (e) {
          debugPrint('LOCAL_REMINDERS_SYNC: ${e.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('PETS_LOAD_FAILED: ${e.runtimeType}: $e');
      if (mounted) {
        setState(() {
          loadError = 'No pudimos cargar tus mascotas. Revisa internet y vuelve a intentarlo.';
          loading = false;
        });
      }
    }
  }

  Future<void> add() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PetEditor()));
    await reload();
  }

  Future<void> delete(Map<String, dynamic> pet) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text('¿Eliminar mascota?'),
                content: Text(
                    'Se eliminarán ${pet['name']} y todos sus cuidados registrados. Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text('Eliminar'))
                ]));
    if (ok == true) {
      await CloudDb.instance.deletePet(pet['id'].toString());
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
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.viewPaddingOf(sheetContext).bottom + 50),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.70),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
            child: Row(children: [
              Icon(Icons.pets_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                (pet['name'] ?? 'Mi mascota').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800,
                    color: colors.onSurface),
              )),
            ]),
          ),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: colors.primary),
            title: const Text('Editar mascota'),
            subtitle: const Text('Actualizar sus datos y fotografía'),
            onTap: () => Navigator.pop(sheetContext, 'edit'),
          ),
          ListTile(
            leading: Icon(Icons.notifications_active_outlined, color: colors.primary),
            title: const Text('Horarios y recordatorios'),
            subtitle: const Text('Gestionar los avisos de cuidado'),
            onTap: () => Navigator.pop(sheetContext, 'reminders'),
          ),
          ListTile(
            leading: Icon(Icons.history_outlined, color: colors.primary),
            title: const Text('Historial de cuidados'),
            subtitle: const Text('Consultar sus registros'),
            onTap: () => Navigator.pop(sheetContext, 'history'),
          ),
          const Divider(height: 16),
          ListTile(
            leading: Icon(Icons.delete_outline, color: colors.error),
            title: Text('Eliminar mascota',
                style: TextStyle(color: colors.error, fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(sheetContext, 'delete'),
          ),
        ]),
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
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => PetEditor(existing: pet),
      ));
      if (mounted) await reload();
    } else if (action == 'reminders') {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => PetRemindersPage(
          petId: petId, petName: petName, species: species,
        ),
      ));
    } else if (action == 'history') {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => PetHistoryPage(petId: petId, petName: petName),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text('PetCare Connect',
              style: TextStyle(fontWeight: FontWeight.w800, color: adaptiveInk(context))),
          actions: [
            if (admin)
              IconButton(
                  tooltip: 'Panel de administrador',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminPage())),
                  icon: Icon(Icons.admin_panel_settings_outlined)),
            PopupMenuButton<String>(
              tooltip: 'Mi cuenta y ajustes',
              position: PopupMenuPosition.under,
              constraints: const BoxConstraints(minWidth: 190, maxWidth: 230),
              icon: Icon(Icons.account_circle_outlined),
              onSelected: (value) async {
                if (value == 'settings') {
                  if (!mounted) return;
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AppearanceSettingsPage(),
                  ));
                } else if (value == 'logout') {
                  if (!amazonBuild) {
                    await PetCareCloudMessaging.instance.unregisterCurrentUser();
                  }
                  await PetCareAlerts.instance.cancelAll();
                  await FirebaseAuth.instance.signOut();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'settings', child: Row(children: [
                  Icon(Icons.settings_outlined, size: 21), SizedBox(width: 10), Text('Apariencia'),
                ])),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: Row(children: [
                  Icon(Icons.logout_rounded, size: 21), SizedBox(width: 10), Text('Cerrar sesión'),
                ])),
              ],
            ),
          ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: add,
          icon: Icon(Icons.add),
          label: Text('Nueva mascota')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.wifi_off_rounded, size: 52, color: Theme.of(context).colorScheme.primary),
                SizedBox(height: 14),
                Text(loadError!, textAlign: TextAlign.center),
                SizedBox(height: 14),
                FilledButton.icon(onPressed: reload,
                  icon: Icon(Icons.refresh),
                  label: Text('Reintentar')),
              ]),
            ))
          : RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  children: [
                    Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                            gradient:
                                LinearGradient(colors: [ink, green]),
                            borderRadius: BorderRadius.circular(28)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tu familia, bien cuidada 🐾',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              SizedBox(height: 8),
                              Text(
                                  'Un espacio para cada mascota y sus cuidados diarios.',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 15))
                            ])),
                    SizedBox(height: 14),
                    if (FirebaseAuth.instance.currentUser?.emailVerified == false &&
                        FirebaseAuth.instance.currentUser?.providerData.any(
                          (provider) => provider.providerId == 'password',
                        ) == true)
                      Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.email_outlined, color: adaptiveInk(context)),
                                SizedBox(width: 9),
                                Expanded(child: Text('Confirma tu correo',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: adaptiveInk(context)))),
                              ]),
                              SizedBox(height: 7),
                              Text('Te enviamos un enlace de verificación. Revisa tu bandeja y spam.'),
                              Wrap(spacing: 8, children: [
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Correo enviado. Revisa tu bandeja y spam.')));
                                    } on FirebaseAuthException catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('No se pudo reenviar el correo: ${e.message ?? e.code}')));
                                    }
                                  },
                                  child: Text('Reenviar correo'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.currentUser?.reload();
                                    if (mounted) setState(() {});
                                  },
                                  child: Text('Ya verifiqué'),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                          child: Text('Mis mascotas',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: adaptiveInk(context)))),
                      Text('${pets.length} registradas',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    ]),
                    SizedBox(height: 14),
                    if (pets.isEmpty)
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(children: [
                                Icon(Icons.pets, size: 58, color: Theme.of(context).colorScheme.primary),
                                SizedBox(height: 12),
                                Text('Aún no tienes mascotas',
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(
                                    'Agrega una mascota y personaliza su perfil.',
                                    textAlign: TextAlign.center),
                                SizedBox(height: 16),
                                FilledButton(
                                    onPressed: add,
                                    child: Text(
                                        'Agregar mi primera mascota'))
                              ])))
                    else
                      ...pets.map((pet) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PetDetail(
                                            petId: pet['id'].toString())));
                                await reload();
                              },
                              child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Row(children: [
                                    CircleAvatar(
                                        radius: 36,
                                        backgroundColor: adaptivePale(context),
                                        backgroundImage: petPhoto(pet),
                                        child: petPhoto(pet) == null
                                            ? Text(emojiFor(pet['species']),
                                                style: TextStyle(
                                                    fontSize: 32))
                                            : null),
                                    SizedBox(width: 14),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text('${pet['name']}',
                                              style: TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                  color: adaptiveInk(context))),
                                          SizedBox(height: 4),
                                          Text(
                                              '${pet['species']} · ${pet['breed']}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: adaptiveMuted(context)))
                                        ])),
                                    IconButton(
                                      tooltip: 'Opciones de ${pet['name']}',
                                      onPressed: () => _showPetActions(pet),
                                      icon: const Icon(Icons.more_vert_rounded),
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    Icon(Icons.chevron_right,
                                        color: Theme.of(context).colorScheme.primary)
                                  ])))))
                  ])));
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
  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    species = (old?['species'] ?? 'Perro').toString();
    if (!speciesCatalog.containsKey(species)) species = 'Perro';
    breed = (old?['breed'] ?? speciesCatalog[species]!.first).toString();
    sex = (old?['sex'] ?? 'No especificado').toString();
    image = old?['imagePath']?.toString();
    name.text = (old?['name'] ?? '').toString();
    age.text = (old?['age'] ?? '').toString();
    weight.text = (old?['weight'] ?? '').toString();
    color.text = (old?['color'] ?? '').toString();
    coat.text = (old?['coat'] ?? '').toString();
    customCoat = coat.text.isNotEmpty && !petCoatOptions(species).contains(coat.text);
  }

  @override
  void dispose() {
    for (final c in [name, age, weight, color, coat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> choosePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 78, maxWidth: 1100);
      if (file == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final photos = Directory(p.join(dir.path, 'pet_photos'));
      await photos.create(recursive: true);
      final ext = p.extension(file.path).toLowerCase();
      final saved = await File(file.path).copy(p.join(photos.path,
          'pet_${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}'));
      if (mounted) setState(() => image = saved.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo seleccionar la fotografía.')));
      }
    }
  }

  Future<void> selectBreed() async {
    final chosen = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BreedSelector(species: species, selected: breed));
    if (chosen != null && mounted) setState(() => breed = chosen);
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Escribe el nombre de tu mascota.')));
      return;
    }
    setState(() => saving = true);
    try {
      final values = <String, dynamic>{
        'name': name.text.trim(),
        'species': species,
        'breed': breed,
        'sex': sex,
        'age': age.text.trim(),
        'weight': weight.text.trim(),
        'color': color.text.trim(),
        'coat': coat.text.trim(),
        'imagePath': image ?? ''
      };
      if (widget.existing == null) {
        await CloudDb.instance.addPet(values);
      } else {
        await CloudDb.instance.updatePet(widget.existing!['id'].toString(), values);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar la mascota.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              widget.existing == null ? 'Nueva mascota' : 'Editar mascota')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          children: [
            Center(
                child: InkWell(
                    onTap: choosePhoto,
                    borderRadius: BorderRadius.circular(70),
                    child: Stack(children: [
                      CircleAvatar(
                          radius: 64,
                          backgroundColor: adaptivePale(context),
                          backgroundImage:
                              image != null && File(image!).existsSync()
                                  ? FileImage(File(image!))
                                  : null,
                          child: image == null || !File(image!).existsSync()
                              ? Text(emojiFor(species),
                                  style: TextStyle(fontSize: 55))
                              : null),
                      Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.camera_alt_outlined)))
                    ]))),
            SizedBox(height: 9),
            Center(
                child: Text('Agregar o cambiar foto',
                    style: TextStyle(color: adaptiveMuted(context)))),
            SizedBox(height: 25),
            Text('Datos principales',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: adaptiveInk(context))),
            SizedBox(height: 12),
            Text('Nombre de la mascota', style: TextStyle(
                color: adaptiveMuted(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                    hintText: 'Ej. Orejitas',
                    prefixIcon: Icon(Icons.badge_outlined))),
            SizedBox(height: 12),
            Text('Especie', style: TextStyle(
                color: adaptiveMuted(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
                initialValue: species,
                decoration: InputDecoration(prefixIcon: Icon(Icons.pets)),
                items: speciesCatalog.keys
                    .map((v) => DropdownMenuItem(
                        value: v, child: Text('${emojiFor(v)}  $v')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      species = v;
                      breed = speciesCatalog[v]!.first;
                      coat.clear();
                      customCoat = false;
                    });
                  }
                }),
            SizedBox(height: 12),
            ListTile(
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                title: Text('Raza / categoría'),
                subtitle:
                    Text(breed, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right),
                onTap: selectBreed),
            SizedBox(height: 12),
            Text('Sexo', style: TextStyle(
                color: adaptiveMuted(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
                initialValue:
                    ['Macho', 'Hembra', 'No especificado'].contains(sex)
                        ? sex
                        : 'No especificado',
                decoration: const InputDecoration(),
                items: ['Macho', 'Hembra', 'No especificado']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => sex = v);
                }),
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Edad', style: TextStyle(color: adaptiveMuted(context))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          hintText: 'Ej. 2',
                          suffixText: age.text.trim() == '1' ? 'año' : 'años'),
                    ),
                  ])),
              SizedBox(width: 10),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Peso', style: TextStyle(color: adaptiveMuted(context))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: weight,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'))
                      ],
                      decoration: InputDecoration(
                          hintText: 'Ej. 15',
                          suffixText: 'kg'),
                    ),
                  ]))
            ]),
            SizedBox(height: 12),
            Card(child: ListTile(
              leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text('Colores'),
              subtitle: Text(color.text.trim().isEmpty
                  ? 'Selecciona uno o varios colores'
                  : color.text.trim()),
              trailing: Icon(Icons.expand_more),
              onTap: () async {
                final value = await choosePetColors(context, color.text);
                if (value != null && mounted) setState(() => color.text = value);
              },
            )),
            SizedBox(height: 12),
            Text(species == 'Ave' ? 'Plumaje'
                : (species == 'Pez' || species == 'Tortuga') ? 'Características' : 'Pelaje',
                style: TextStyle(color: adaptiveMuted(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              key: ValueKey('pelaje-$species'),
              isExpanded: true,
              initialValue: customCoat
                  ? 'Otro (especificar)'
                  : petCoatOptions(species).contains(coat.text) ? coat.text : null,
              // Cuando aún no se ha elegido una opción, muestra una instrucción
              // legible en ambos temas (antes el desplegable se veía vacío).
              hint: Text(
                species == 'Ave'
                    ? 'Selecciona el plumaje'
                    : (species == 'Pez' || species == 'Tortuga')
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
              items: [...petCoatOptions(species), 'Otro (especificar)']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
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
              TextField(controller: coat,
                  decoration: InputDecoration(
                    labelText: 'Describe el pelaje o característica',
                    hintText: 'Ej. corto y rizado',
                  )),
            ],
            const SizedBox(height: 26),
          ]),
      bottomNavigationBar: petCareActionFooter(
        context,
        FilledButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.check),
          label: Text(saving ? 'Guardando...'
              : widget.existing == null ? 'Guardar mascota' : 'Guardar cambios'),
        ),
      ));
}

class BreedSelector extends StatefulWidget {
  final String species, selected;
  const BreedSelector(
      {super.key, required this.species, required this.selected});
  @override
  State<BreedSelector> createState() => _BreedSelectorState();
}

class _BreedSelectorState extends State<BreedSelector> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final list = speciesCatalog[widget.species]!
        .where((v) => v.toLowerCase().contains(search.trim().toLowerCase()))
        .toList();
    return SafeArea(
        child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
                height: MediaQuery.of(context).size.height * .75,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Razas y categorías · ${widget.species}',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: adaptiveInk(context))),
                            SizedBox(height: 12),
                            TextField(
                                autofocus: true,
                                decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: 'Buscar raza o categoría'),
                                onChanged: (v) => setState(() => search = v))
                          ])),
                  SizedBox(height: 8),
                  Expanded(
                      child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final value = list[i];
                            return ListTile(
                                title: Text(value),
                                trailing: value == widget.selected
                                    ? Icon(Icons.check_circle,
                                        color: Theme.of(context).colorScheme.primary)
                                    : null,
                                onTap: () => Navigator.pop(context, value));
                          })),
                ]))));
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

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final current = await CloudDb.instance.pet(widget.petId);
    final entries = await CloudDb.instance.care(widget.petId);
    final types = current == null
        ? <Map<String, dynamic>>[]
        : await CloudDb.instance
            .careCatalogForSpecies((current['species'] ?? '').toString());
    final hidden = (current?['hiddenCareIds'] as List?)
            ?.map((value) => value.toString()).toSet() ??
        <String>{};
    final visible = types.where(
      (type) => !hidden.contains((type['id'] ?? '').toString()),
    ).toList();

    if (mounted) {
      setState(() {
        pet = current;
        history = entries;
        careTypes = visible;
      });
    }
  }

  Future<void> mark(Map<String, dynamic> careType) async {
    await CloudDb.instance.addCare(widget.petId, careType);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final current = pet;
    if (current == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = history.where(isToday).toList();
    final completed = careTypes.where((type) {
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
                MaterialPageRoute(
                  builder: (_) => PetEditor(existing: current),
                ),
              );
              await load();
            },
            icon: Icon(Icons.edit_outlined),
          )
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
                gradient: LinearGradient(colors: [ink, green]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white24,
                    backgroundImage: petPhoto(current),
                    child: petPhoto(current) == null
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
                    '${current['species']} · ${current['breed']}',
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
                      value: careTypes.isEmpty
                          ? 0
                          : completed / careTypes.length,
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
                    Row(children: [
                      Icon(Icons.health_and_safety_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 9),
                      Expanded(child: Text('Su rutina de cuidados',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: adaptiveInk(context)))),
                    ]),
                    const SizedBox(height: 5),
                    Text('Horarios, historial y cuidados a su medida.',
                        style: TextStyle(fontSize: 12,
                            color: adaptiveMuted(context))),
                    const SizedBox(height: 13),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PetRemindersPage(
                            petId: widget.petId,
                            petName: (current['name'] ?? 'tu mascota').toString(),
                            species: (current['species'] ?? '').toString(),
                          ),
                        ));
                        await load();
                      },
                      icon: Icon(Icons.notifications_active_outlined),
                      label: Text('Horarios y recordatorios'),
                    ),
                    SizedBox(height: 7),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PetHistoryPage(
                            petId: widget.petId,
                            petName: (current['name'] ?? 'Mascota').toString(),
                          ),
                        ));
                        await load();
                      },
                      icon: Icon(Icons.calendar_month_outlined),
                      label: Text('Ver historial de cuidados'),
                    ),
                    SizedBox(height: 7),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PetCareVisibilityPage(
                            petId: widget.petId,
                            petName: (current['name'] ?? 'Mascota').toString(),
                            species: (current['species'] ?? '').toString(),
                          ),
                        ));
                        await load();
                      },
                      icon: Icon(Icons.tune_outlined),
                      label: Text('Personalizar cuidados'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
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
                    children: careTypes.map((type) {
                      final id = (type['id'] ?? '').toString();
                      final done = today.any(
                        (row) => (row['type'] ?? '').toString() == id,
                      );
                      return SizedBox(
                        width: width,
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => mark(type),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        done ? Theme.of(context).colorScheme.primaryContainer
                                            : Theme.of(context).colorScheme.secondaryContainer,
                                    child: Icon(
                                      done ? Icons.check : careTypeIcon(type),
                                      color: done ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    careTypeLabel(type),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: adaptiveInk(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if ((type['description'] ?? '').toString().trim().isNotEmpty) ...[
                                    SizedBox(height: 5),
                                    Text(
                                      type['description'].toString(),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: adaptiveMuted(context)),
                                    ),
                                  ],
                                  SizedBox(height: 4),
                                  Text(
                                    done
                                        ? 'Registrado hoy · repetir'
                                        : 'Registrar cuidado',
                                    style: TextStyle(
                                      color: adaptiveMuted(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                    detailRow(
                      'Edad',
                      petAgeLabel(current['age']),
                    ),
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
                final dateText = date == null
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
