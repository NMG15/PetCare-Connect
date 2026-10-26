part of '../main.dart';

String homeGreeting(String? rawName) {
  final name = (rawName ?? '').trim();
  if (name.isEmpty) return 'Bienvenido a tu familia';
  final first = name.split(RegExp(r'\s+')).first;
  return 'Hola, $first';
}

String petSpeciesName(Map<String, dynamic> pet) {
  final species = (pet['species'] ?? '').toString();
  if (species != 'Otra especie') return species;
  final custom = (pet['customSpecies'] ?? '').toString().trim();
  return custom.isEmpty ? species : custom;
}

String petSpeciesDescription(Map<String, dynamic> pet) {
  final species = petSpeciesName(pet);
  final breed = (pet['breed'] ?? '').toString().trim();
  return breed.isEmpty || breed == 'Raza sin especificar'
      ? species
      : '$species · $breed';
}

String petTimeAmPm(int hour, int minute) {
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
}

String? validateCustomSpecies(String species, String value) {
  if (species != 'Otra especie') return null;
  final name = value.trim();
  if (name.isEmpty) return 'Especifica qué animal es.';
  if (name.length > 50) {
    return 'La especie debe tener 50 caracteres como máximo.';
  }
  return null;
}

bool reminderAppliesOnDate(Map<String, dynamic> reminder, DateTime date) {
  if (reminder['enabled'] == false) return false;
  final hour = (reminder['hour'] as num?)?.toInt();
  final minute = (reminder['minute'] as num?)?.toInt();
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return false;
  }
  final rawDays = reminder['days'];
  final days =
      rawDays is List
          ? rawDays
              .whereType<num>()
              .map((value) => value.toInt())
              .where((value) => value >= 1 && value <= 7)
              .toSet()
          : <int>{};
  return days.isEmpty || days.contains(date.weekday);
}

String petAgeLabel(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return '';
  final numeric = int.tryParse(raw);
  if (numeric == null) return raw;
  return '$numeric ${numeric == 1 ? 'año' : 'años'}';
}

DateTime? nextPetReminder(Map<String, dynamic> reminder, DateTime now) {
  if (reminder['enabled'] == false) return null;
  final hour = (reminder['hour'] as num?)?.toInt();
  final minute = (reminder['minute'] as num?)?.toInt();
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  final raw = reminder['days'];
  final days =
      raw is List
          ? raw
              .whereType<num>()
              .map((day) => day.toInt())
              .where((day) => day >= 1 && day <= 7)
              .toSet()
          : <int>{};
  final allDays = days.isEmpty;
  for (var delta = 0; delta <= 7; delta++) {
    final calendarDay = DateTime(now.year, now.month, now.day + delta);
    if (!allDays && !days.contains(calendarDay.weekday)) continue;
    final occurrence = DateTime(
      calendarDay.year,
      calendarDay.month,
      calendarDay.day,
      hour,
      minute,
    );
    if (occurrence.isAfter(now)) return occurrence;
  }
  return null;
}

String? validatePetData({
  required String name,
  required String age,
  required String weight,
}) {
  if (name.trim().isEmpty) return 'Escribe el nombre de tu mascota.';
  if (name.trim().length > 60) {
    return 'El nombre debe tener 60 caracteres como máximo.';
  }
  final ageValue = age.trim();
  if (ageValue.isNotEmpty) {
    final years = int.tryParse(ageValue);
    if (years == null || years < 0 || years > 150) {
      return 'Escribe una edad válida entre 0 y 150 años.';
    }
  }
  final weightValue = weight.trim();
  if (weightValue.isNotEmpty) {
    final kg = double.tryParse(weightValue);
    if (kg == null || !kg.isFinite || kg <= 0 || kg > 2000) {
      return 'Escribe un peso válido mayor que 0 y menor que 2000 kg.';
    }
  }
  return null;
}

const petColorOptions = <String>[
  'Negro',
  'Blanco',
  'Café',
  'Chocolate',
  'Beige',
  'Crema',
  'Dorado',
  'Gris',
  'Plateado',
  'Naranja',
  'Amarillo',
  'Rojizo',
  'Canela',
  'Atigrado',
  'Manchado',
  'Multicolor',
];

List<String> petCoatOptions(String species) {
  if (species == 'Ave') {
    return ['Corto', 'Medio', 'Largo', 'Abundante', 'Escaso', 'Sin plumas'];
  }
  if (species == 'Pez') {
    return [
      'Escamas lisas',
      'Escamas brillantes',
      'Aletas largas',
      'Aletas cortas',
      'Sin escamas',
      'No especificado',
    ];
  }
  if (species == 'Tortuga') {
    return [
      'Caparazón liso',
      'Caparazón rugoso',
      'Caparazón con patrones',
      'Caparazón abovedado',
      'Caparazón aplanado',
      'Caparazón blando',
      'Caparazón con dibujos',
      'No especificado',
    ];
  }
  if (species == 'Iguana') {
    return [
      'Escamas verdes',
      'Escamas oscuras',
      'Escamas moteadas',
      'No especificado',
    ];
  }
  if (species == 'Erizo') {
    return [
      'Púas cortas',
      'Púas largas',
      'Púas claras',
      'Púas oscuras',
      'No especificado',
    ];
  }
  return [
    'Corto',
    'Medio',
    'Largo',
    'Muy largo',
    'Rizado',
    'Doble',
    'Sin pelo',
    'No aplica',
  ];
}

List<String> petColorsForSpecies(String species) {
  switch (species) {
    case 'Tortuga':
      return [
        'Verde oliva',
        'Verde oscuro',
        'Marrón',
        'Café',
        'Negro',
        'Amarillo',
        'Beige',
        'Gris',
        'Moteado',
        'Multicolor',
      ];
    case 'Pez':
      return [
        'Naranja',
        'Rojo',
        'Dorado',
        'Amarillo',
        'Azul',
        'Verde',
        'Plateado',
        'Blanco',
        'Negro',
        'Iridescente',
        'Multicolor',
      ];
    case 'Iguana':
      return [
        'Verde',
        'Verde oliva',
        'Marrón',
        'Gris',
        'Naranja',
        'Azulado',
        'Amarillo',
        'Moteado',
      ];
    case 'Ave':
      return [
        'Verde',
        'Azul',
        'Rojo',
        'Amarillo',
        'Blanco',
        'Negro',
        'Gris',
        'Café',
        'Naranja',
        'Multicolor',
      ];
    default:
      return petColorOptions;
  }
}

Future<String?> choosePetColors(
  BuildContext context,
  String current, {
  String species = 'Perro',
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PetColorSheet(initial: current, species: species),
  );
}

class _PetColorSheet extends StatefulWidget {
  final String initial;
  final String species;
  const _PetColorSheet({required this.initial, required this.species});
  @override
  State<_PetColorSheet> createState() => _PetColorSheetState();
}

class _PetColorSheetState extends State<_PetColorSheet> {
  final selected = <String>{};
  final custom = TextEditingController();
  List<String> get options => petColorsForSpecies(widget.species);
  @override
  void initState() {
    super.initState();
    final parts = widget.initial.split(
      RegExp(r'\s*(?:,|\sy\s|\scon\s)\s*', caseSensitive: false),
    );
    for (final part in parts) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final standard = options.where(
        (e) => e.toLowerCase() == value.toLowerCase(),
      );
      if (standard.isNotEmpty) {
        selected.add(standard.first);
      } else {
        custom.text = custom.text.isEmpty ? value : '${custom.text}, $value';
      }
    }
  }

  @override
  void dispose() {
    custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        6,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colores de tu ${widget.species.toLowerCase()}',
              style: TextStyle(
                color: adaptiveInk(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Selecciona uno o varios colores. También puedes escribir otro tono.',
              style: TextStyle(color: adaptiveMuted(context)),
            ),
            SizedBox(height: 18),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children:
                  options
                      .map(
                        (value) => FilterChip(
                          label: Text(value),
                          selected: selected.contains(value),
                          selectedColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF276245)
                                  : const Color(0xFFB2E5C7),
                          checkmarkColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF134A2E),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                selected.contains(value)
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color:
                                selected.contains(value)
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                            width: selected.contains(value) ? 1.6 : 1,
                          ),
                          onSelected:
                              (yes) => setState(() {
                                if (yes) {
                                  selected.add(value);
                                } else {
                                  selected.remove(value);
                                }
                              }),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 14),
            TextField(
              controller: custom,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Otro color o combinación (opcional)',
                hintText: 'Ej. café claro con blanco',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  final result = [
                    ...options.where(selected.contains),
                    if (custom.text.trim().isNotEmpty) custom.text.trim(),
                  ];
                  if (result.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Elige o escribe al menos un color.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, result.join(' con '));
                },
                icon: Icon(Icons.check),
                label: Text('Guardar colores'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
