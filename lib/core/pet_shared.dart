part of '../main.dart';


String petAgeLabel(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return '';
  final numeric = int.tryParse(raw);
  if (numeric == null) return raw;
  return '$numeric ${numeric == 1 ? 'año' : 'años'}';
}

const petColorOptions = <String>[
  'Negro', 'Blanco', 'Café', 'Chocolate', 'Beige', 'Crema',
  'Dorado', 'Gris', 'Plateado', 'Naranja', 'Amarillo',
  'Rojizo', 'Canela', 'Atigrado', 'Manchado', 'Multicolor',
];

List<String> petCoatOptions(String species) {
  if (species == 'Ave') {
    return ['Corto', 'Medio', 'Largo', 'Abundante', 'Escaso', 'Sin plumas'];
  }
  if (species == 'Pez' || species == 'Tortuga') {
    return ['Liso', 'Escamas', 'Caparazón liso', 'Caparazón rugoso', 'No aplica'];
  }
  return ['Corto', 'Medio', 'Largo', 'Muy largo', 'Rizado',
    'Doble', 'Sin pelo', 'No aplica'];
}

Future<String?> choosePetColors(BuildContext context, String current) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PetColorSheet(initial: current),
  );
}

class _PetColorSheet extends StatefulWidget {
  final String initial;
  const _PetColorSheet({required this.initial});
  @override
  State<_PetColorSheet> createState() => _PetColorSheetState();
}

class _PetColorSheetState extends State<_PetColorSheet> {
  final selected = <String>{};
  final custom = TextEditingController();
  @override
  void initState() {
    super.initState();
    final parts = widget.initial.split(RegExp(r'\s*(?:,|\sy\s|\scon\s)\s*', caseSensitive: false));
    for (final part in parts) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final standard = petColorOptions.where(
          (e) => e.toLowerCase() == value.toLowerCase());
      if (standard.isNotEmpty) {
        selected.add(standard.first);
      } else {
        custom.text = custom.text.isEmpty ? value : '${custom.text}, $value';
      }
    }
  }

  @override
  void dispose() { custom.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(20, 6, 20,
          MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Colores de tu mascota', style: TextStyle(
              color: adaptiveInk(context), fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Selecciona uno o varios colores. También puedes escribir otro tono.',
              style: TextStyle(color: adaptiveMuted(context))),
          SizedBox(height: 18),
          Wrap(spacing: 7, runSpacing: 6,
            children: petColorOptions.map((value) => FilterChip(
              label: Text(value),
              selected: selected.contains(value),
              selectedColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF276245) : const Color(0xFFB2E5C7),
              checkmarkColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFFFFFFF) : const Color(0xFF134A2E),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: selected.contains(value)
                    ? FontWeight.w800 : FontWeight.w500,
              ),
              side: BorderSide(
                color: selected.contains(value)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: selected.contains(value) ? 1.6 : 1,
              ),
              onSelected: (yes) => setState(() {
                if (yes) { selected.add(value); } else { selected.remove(value); }
              }),
            )).toList(),
          ),
          SizedBox(height: 14),
          TextField(controller: custom, textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Otro color o combinación (opcional)',
              hintText: 'Ej. café claro con blanco',
              prefixIcon: Icon(Icons.palette_outlined),
            )),
          SizedBox(height: 18),
          SizedBox(width: double.infinity, height: 52,
            child: FilledButton.icon(
              onPressed: () {
                final result = [...petColorOptions.where(selected.contains),
                  if (custom.text.trim().isNotEmpty) custom.text.trim()];
                if (result.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Elige o escribe al menos un color.')));
                  return;
                }
                Navigator.pop(context, result.join(' con '));
              },
              icon: Icon(Icons.check),
              label: Text('Guardar colores'),
            ),
          ),
        ]),
      ),
    ),
  );
}
