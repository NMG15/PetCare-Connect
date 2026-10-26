part of '../main.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  Uint8List? _profilePhotoBytes;
  bool _changingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPhoto();
  }

  Future<File> _photoFile(String uid) async {
    final directory = await getApplicationDocumentsDirectory();

    final folder = Directory(p.join(directory.path, 'profile_photos'));

    await folder.create(recursive: true);

    return File(p.join(folder.path, '$uid.avatar'));
  }

  Future<void> _loadSavedPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      final file = await _photoFile(uid);

      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      setState(() {
        _profilePhotoBytes = bytes;
      });
    } catch (_) {}
  }

  Future<void> _changeProfilePhoto() async {
    if (_changingPhoto) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para cambiar tu fotografía.'),
        ),
      );
      return;
    }

    setState(() => _changingPhoto = true);

    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (selected == null) return;

      final imageBytes = await selected.readAsBytes();

      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ProfilePhotoCropPage(imageBytes: imageBytes),
        ),
      );

      if (croppedBytes == null || !mounted) return;

      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      final file = await _photoFile(uid);

      await file.writeAsBytes(croppedBytes, flush: true);

      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      setState(() {
        _profilePhotoBytes = croppedBytes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotografía guardada en este dispositivo.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo actualizar la fotografía. Inténtalo nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _changingPhoto = false);
      }
    }
  }

  bool _savingName = false;

  String get _visibleName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    return name.isEmpty ? 'Mi cuenta' : name;
  }

  Future<void> _editName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para editar tu perfil.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    var proposedName = user.displayName?.trim() ?? '';

    final newName = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Editar mi nombre'),
            content: Form(
              key: formKey,
              child: TextFormField(
                initialValue: proposedName,
                autofocus: true,
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final name = (value ?? '').trim();

                  if (name.length < 2) {
                    return 'Escribe al menos 2 caracteres.';
                  }

                  return null;
                },
                onSaved: (value) {
                  proposedName = (value ?? '').trim();
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;

                  formKey.currentState!.save();
                  Navigator.pop(dialogContext, proposedName);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (!mounted || newName == null) return;

    if (newName == (user.displayName?.trim() ?? '')) return;

    setState(() => _savingName = true);

    var authUpdated = false;

    try {
      await user.updateDisplayName(newName);
      authUpdated = true;

      await CloudDb.instance.saveUserProfile(user, name: newName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado correctamente.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authUpdated
                ? 'El nombre cambió en tu cuenta, pero falta sincronizarlo.'
                : 'No se pudo actualizar el nombre. Inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta y apariencia')),
      body: SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: PetCareAppearance.mode,
          builder:
              (context, selected, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                children: [
                  const PetCarePageIntro(
                    eyebrow: 'Tu espacio PetCare',
                    title: 'A tu manera',
                    subtitle:
                        'Personaliza tu perfil y la apariencia de la aplicación.',
                    icon: Icons.palette_outlined,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          PetCareProfileAvatar(
                            radius: 24,
                            localPhotoBytes: _profilePhotoBytes,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _visibleName,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FirebaseAuth.instance.currentUser?.email ??
                                      'Sesión iniciada',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _savingName ? null : _editName,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      _savingName ? 'Guardando...' : 'Editar mi nombre',
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _changingPhoto ? null : _changeProfilePhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _changingPhoto
                          ? 'Procesando fotografía...'
                          : 'Cambiar fotografía',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const PetCareSectionTitle(
                    title: 'Apariencia',
                    caption: 'Elige el ambiente que más te guste.',
                  ),
                  _option(
                    context,
                    selected,
                    ThemeMode.system,
                    Icons.brightness_auto_outlined,
                    'Automático',
                    'Usar automáticamente el tema del teléfono',
                  ),
                  _option(
                    context,
                    selected,
                    ThemeMode.light,
                    Icons.light_mode_outlined,
                    'Claro',
                    'Fondo claro',
                  ),
                  _option(
                    context,
                    selected,
                    ThemeMode.dark,
                    Icons.dark_mode_outlined,
                    'Oscuro',
                    'Negro y grafito con verde esmeralda',
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context,
    ThemeMode current,
    ThemeMode value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        color:
            selected ? colors.surfaceContainerHigh : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 0.9,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Semantics(
          selected: selected,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            trailing: Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            onTap: () => PetCareAppearance.update(value),
          ),
        ),
      ),
    );
  }
}

class PetCareProfileAvatar extends StatelessWidget {
  const PetCareProfileAvatar({
    super.key,
    required this.radius,
    this.localPhotoBytes,
  });

  final double radius;
  final Uint8List? localPhotoBytes;

  Future<Uint8List?> _readSavedPhoto(String uid) async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final photo = File(
        p.join(documents.path, 'profile_photos', '$uid.avatar'),
      );
      if (!await photo.exists()) return null;
      final bytes = await photo.readAsBytes();
      if (FirebaseAuth.instance.currentUser?.uid != uid) return null;
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    String? googlePhotoUrl;
    if (user != null) {
      final possibleUrls = <String>[
        if (user.photoURL != null) user.photoURL!,
        for (final provider in user.providerData)
          if (provider.providerId == 'google.com' && provider.photoURL != null)
            provider.photoURL!,
      ];
      for (final candidate in possibleUrls) {
        final url = candidate.trim();
        if (Uri.tryParse(url)?.scheme == 'https') {
          googlePhotoUrl = url;
          break;
        }
      }
    }

    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List?>(
      key: ValueKey(uid),
      future:
          uid == null ? Future<Uint8List?>.value(null) : _readSavedPhoto(uid),
      builder: (context, snapshot) {
        final sameAccount =
            uid != null && FirebaseAuth.instance.currentUser?.uid == uid;
        final bytes = sameAccount ? (localPhotoBytes ?? snapshot.data) : null;
        return CircleAvatar(
          radius: radius,
          backgroundColor: colors.primaryContainer,
          foregroundImage:
              bytes != null
                  ? MemoryImage(bytes)
                  : (!sameAccount || googlePhotoUrl == null
                      ? null
                      : NetworkImage(googlePhotoUrl)),
          child: Icon(
            Icons.person_outline,
            color: colors.onPrimaryContainer,
            size: radius * 1.15,
          ),
        );
      },
    );
  }
}
