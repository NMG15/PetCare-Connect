part of '../main.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
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
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colors.primaryContainer,
                            child: Icon(
                              Icons.person_outline,
                              color: colors.onPrimaryContainer,
                            ),
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
