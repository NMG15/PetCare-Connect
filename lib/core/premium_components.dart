// Componentes visuales Premium V2. No realizan operaciones con Firebase.
part of '../main.dart';

/// Encabezado «Signature» reutilizable en usuario y administración.
class PetCareSignatureHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  const PetCareSignatureHero({super.key, required this.eyebrow,
    required this.title, required this.subtitle,
    this.icon = Icons.pets_rounded, this.action});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: dark
            ? const [Color(0xFF26292D), Color(0xFF16191C)]
            : const [Color(0xFF174F3B), Color(0xFF0B3729)],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: dark ? const Color(0xFF3E4447) : const Color(0xFF24664C)),
      ),
      child: Stack(children: [
        Positioned(right: -55, bottom: -60, child: Icon(icon,
          size: 170, color: Colors.white.withValues(alpha: 0.07))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow.toUpperCase(), style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w800,
            letterSpacing: 1.9,
            color: dark ? Theme.of(context).colorScheme.primary
              : const Color(0xFFB8EDCC))),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white,
            fontSize: 28, letterSpacing: -0.8,
            fontWeight: FontWeight.w800, height: 1.12)),
          const SizedBox(height: 11),
          Text(subtitle, style: TextStyle(
            color: dark ? const Color(0xFFC7CDCA) : const Color(0xFFD4E9DC),
            fontSize: 13.5, height: 1.45)),
          if (action != null) ...[
            const SizedBox(height: 17), action!,
          ],
        ]),
      ]),
    );
  }
}

class PetCareSectionTitle extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  const PetCareSectionTitle({super.key, required this.title,
    this.caption, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 10, 1, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: c.onSurface,
              fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.45)),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, style: TextStyle(
                fontSize: 12.5, color: c.onSurfaceVariant)),
            ],
          ])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class PetCareMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const PetCareMetric({super.key, required this.value,
    required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Expanded(child: Container(
      constraints: const BoxConstraints(minHeight: 109),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(color: c.surfaceContainerLow,
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.75)),
        borderRadius: BorderRadius.circular(21)),
      child: Column(children: [
        Icon(icon, size: 18, color: c.primary),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 23,
          fontWeight: FontWeight.w900, color: c.onSurface)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: c.onSurfaceVariant,
              fontWeight: FontWeight.w600)),
      ]),
    ));
  }
}

class PetCareActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const PetCareActionTile({super.key, required this.title,
    required this.subtitle, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(
        horizontal: 17, vertical: 15),
        child: Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(color: c.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: c.primary)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.35,
                  color: c.onSurfaceVariant)),
            ])),
          const SizedBox(width: 7),
          Icon(Icons.chevron_right_rounded, color: c.primary),
        ])),
    ));
  }
}

class PetCarePageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  const PetCarePageIntro({super.key, required this.eyebrow,
    required this.title, required this.subtitle,
    this.icon = Icons.auto_awesome_outlined});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.primaryContainer,
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: c.primary, size: 23)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow.toUpperCase(), style: TextStyle(
              color: c.primary,
              fontSize: 10, fontWeight: FontWeight.w800,
              letterSpacing: 1.1)),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
            const SizedBox(height: 5),
            Text(subtitle, style: TextStyle(fontSize: 12.5, height: 1.35,
              color: c.onPrimaryContainer)),
          ])),
      ]),
    );
  }
}

/// Barra de navegación: solo mueve entre secciones reales de PetCare.
class PetCareBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  final bool admin;
  const PetCareBottomNav({super.key, required this.selected,
    required this.onSelected, this.admin = false});
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selected,
    onDestinationSelected: onSelected,
    destinations: admin ? const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.people_outline_rounded),
        selectedIcon: Icon(Icons.people_rounded), label: 'Usuarios'),
      NavigationDestination(icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune_rounded), label: 'Cuidados'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded), label: 'Cuenta'),
    ] : const [
      NavigationDestination(icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.pets_outlined),
        selectedIcon: Icon(Icons.pets_rounded), label: 'Mascotas'),
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Agenda'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded), label: 'Cuenta'),
    ],
  );
}


/// V33: selector tactil compacto. El panel nunca ocupa toda la pantalla.
/// Componente exclusivamente visual, no almacena ni modifica datos.
class PetCareSelectOption {
  final String value;
  final String label;
  final IconData? icon;
  const PetCareSelectOption({required this.value, required this.label, this.icon});
}

class PetCareCompactSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<PetCareSelectOption> options;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String placeholder;
  const PetCareCompactSelector({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon = Icons.tune_rounded,
    this.placeholder = 'Selecciona una opción',
  });

  Future<void> _open(BuildContext context) async {
    if (options.isEmpty) return;
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final limit = MediaQuery.sizeOf(sheetContext).height * .58;
        final proposed = 84.0 + options.length * 55.0;
        return SizedBox(
          height: proposed < limit ? proposed : limit,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(label, style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
              ),
            ),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: options.length,
              itemBuilder: (_, index) {
                final option = options[index];
                final active = option.value == value;
                return ListTile(
                  key: ValueKey('petcare-choice-${option.value}'),
                  minTileHeight: 52,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                  tileColor: active ? scheme.primaryContainer : null,
                  leading: option.icon == null ? null : Icon(option.icon,
                    color: active ? scheme.primary : scheme.onSurfaceVariant),
                  title: Text(option.label, maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  trailing: active ? Icon(Icons.check_circle_rounded,
                    color: scheme.primary) : null,
                  onTap: () => Navigator.pop(sheetContext, option.value),
                );
              },
            )),
          ]),
        );
      },
    );
    if (next != null && next != value && context.mounted) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    PetCareSelectOption? selected;
    for (final option in options) {
      if (option.value == value) {selected = option; break;}
    }
    return Semantics(
      button: true,
      label: 'Elegir $label',
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('petcare-selector-$label'),
          borderRadius: BorderRadius.circular(16),
          onTap: options.isEmpty ? null : () => _open(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(children: [
              Icon(icon, color: scheme.primary, size: 22),
              const SizedBox(width: 13),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12,
                    color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 3),
                  Text(selected?.label ?? placeholder,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: selected == null
                        ? scheme.onSurfaceVariant : scheme.onSurface)),
                ],
              )),
              Icon(Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }
}


/// V35: todas las tarjetas ocupan la misma altura en ambos temas.
/// El icono queda arriba; el nombre y el estado se alinean abajo.
class PetCareTodayTile extends StatelessWidget {
  final Map<String, dynamic> care;
  final int countToday;
  final bool saving;
  final VoidCallback onTap;

  const PetCareTodayTile({super.key, required this.care,
    required this.countToday, required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final done = countToday > 0;
    final accent = dark ? const Color(0xFF47E6A1) : const Color(0xFF13694D);
    final bg = done
        ? (dark ? const Color(0xFF13372B) : const Color(0xFFDFF6E9))
        : theme.cardColor;
    // Altura uniforme incluso con etiquetas de dos lineas y fuentes grandes.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final tileHeight = (164.0 * scale).clamp(164.0, 260.0).toDouble();
    return Semantics(
      button: true,
      enabled: !saving,
      label: '${careTypeLabel(care)}. '
          '${done ? "Registrado $countToday veces hoy" : "Sin registrar hoy"}. '
          'Toca para registrar cuidado.',
      child: SizedBox(
        height: tileHeight,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
            side: BorderSide(
              color: done ? accent : theme.colorScheme.outlineVariant,
              width: done ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: saving ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: done ? accent : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: saving
                          ? Padding(padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2,
                              color: done ? (dark ? const Color(0xFF052819)
                                  : Colors.white) : accent))
                          : Icon(done ? Icons.check_rounded : careTypeIcon(care),
                              color: done ? (dark ? const Color(0xFF052819)
                                  : Colors.white)
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 21),
                    ),
                    const Spacer(),
                    if (done) Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: dark ? 0.16 : 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text('HECHO', style: TextStyle(
                        color: accent, fontSize: 10,
                        fontWeight: FontWeight.w900,
                      )),
                    ),
                  ]),
                  const Spacer(),
                  Text(careTypeLabel(care),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800, fontSize: 14,
                    )),
                  const SizedBox(height: 5),
                  Text(done
                    ? '$countToday ${countToday == 1 ? "vez" : "veces"} hoy · repetir'
                    : 'Toca para registrar',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                      color: done ? accent : theme.colorScheme.onSurfaceVariant,
                    )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
