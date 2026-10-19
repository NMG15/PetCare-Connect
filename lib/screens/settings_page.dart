// Ajustes de apariencia. Se mantienen los datos existentes de Firebase.
part of '../main.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta y apariencia')),
      body: SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: PetCareAppearance.mode,
          builder: (context, selected, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
            children: [
              const PetCarePageIntro(
                eyebrow: 'Tu espacio PetCare',
                title: 'A tu manera',
                subtitle: 'Personaliza la aplicación sin cambiar tus datos.',
                icon: Icons.palette_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(Icons.person_outline,
                        color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi cuenta', style: TextStyle(
                          color: colors.onSurface, fontSize: 17,
                          fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(FirebaseAuth.instance.currentUser?.email
                                ?? 'Sesión iniciada',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant)),
                      ],
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              const PetCareSectionTitle(
                title: 'Apariencia',
                caption: 'Elige el ambiente que más te guste.',
              ),
              _option(context, selected, ThemeMode.system,
                Icons.brightness_auto_outlined, 'Automático',
                'Usar automáticamente el tema del teléfono'),
              _option(context, selected, ThemeMode.light,
                Icons.light_mode_outlined, 'Claro', 'Fondo claro'),
              _option(context, selected, ThemeMode.dark,
                Icons.dark_mode_outlined, 'Oscuro', 'Negro y grafito con verde esmeralda'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(BuildContext context, ThemeMode current,
      ThemeMode value, IconData icon, String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        color: selected ? colors.surfaceContainerHigh : colors.surfaceContainerLow,
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
              horizontal: 16, vertical: 8),
            leading: Icon(icon, color: selected
              ? colors.primary : colors.onSurfaceVariant),
            title: Text(title, style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.onSurface)),
            subtitle: Text(subtitle, style: TextStyle(
              color: colors.onSurfaceVariant)),
            trailing: Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? colors.primary : colors.onSurfaceVariant),
            onTap: () => PetCareAppearance.update(value),
          ),
        ),
      ),
    );
  }
}
