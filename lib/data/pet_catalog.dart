part of '../main.dart';

const speciesCatalog = <String, List<String>>{
  'Perro': [
    'Akita Inu',
    'Alaskan Malamute',
    'American Bully',
    'American Staffordshire Terrier',
    'Basenji',
    'Basset Hound',
    'Beagle',
    'Bichón Frisé',
    'Border Collie',
    'Boston Terrier',
    'Boxer',
    'Bulldog Francés',
    'Bulldog Inglés',
    'Bull Terrier',
    'Calupoh (perro lobo mexicano)',
    'Caniche / Poodle',
    'Cane Corso',
    'Chihuahua',
    'Chow Chow',
    'Cocker Spaniel',
    'Dálmata',
    'Dóberman',
    'Dogo Argentino',
    'Fox Terrier',
    'Galgo',
    'Golden Retriever',
    'Gran Danés',
    'Husky Siberiano',
    'Jack Russell Terrier',
    'Labrador Retriever',
    'Maltés',
    'Mestizo / Sin raza definida',
    'Raza sin especificar',
    'Pastor Alemán',
    'Pastor Australiano',
    'Pastor Belga Malinois',
    'Pastor Inglés',
    'Pequinés',
    'Pinscher Miniatura',
    'Pitbull (tipo)',
    'Pomerania',
    'Pug',
    'Rottweiler',
    'Samoyedo',
    'San Bernardo',
    'Schnauzer',
    'Setter Irlandés',
    'Shar Pei',
    'Shiba Inu',
    'Shih Tzu',
    'Teckel / Dachshund',
    'Terranova',
    'Weimaraner',
    'West Highland White Terrier',
    'Whippet',
    'Xoloitzcuintle',
    'Yorkshire Terrier',
  ],
  'Gato': [
    'Abisinio',
    'American Shorthair',
    'Angora Turco',
    'Azul Ruso',
    'Bengalí',
    'Birmano',
    'Bombay',
    'Bosque de Noruega',
    'British Shorthair',
    'Burmés',
    'Cornish Rex',
    'Devon Rex',
    'Europeo de pelo corto',
    'Exótico de pelo corto',
    'Himalayo',
    'Maine Coon',
    'Manx',
    'Mestizo / Doméstico',
    'Munchkin',
    'Oriental de pelo corto',
    'Raza sin especificar',
    'Persa',
    'Ragdoll',
    'Sagrado de Birmania',
    'Scottish Fold',
    'Selkirk Rex',
    'Siamés',
    'Siberiano',
    'Singapura',
    'Somalí',
    'Sphynx',
    'Tonkinés',
    'Turco Van',
  ],
  'Conejo': [
    'Angora',
    'Cabeza de León',
    'Californiano',
    'Enano Holandés',
    'Gigante de Flandes',
    'Holland Lop',
    'Mini Lop',
    'Mestizo / Sin raza definida',
    'Raza sin especificar',
    'Rex',
  ],
  'Hámster': [
    'Sirio / Dorado',
    'Ruso de Campbell',
    'Ruso de invierno',
    'Roborovski',
    'Chino',
    'Raza sin especificar',
  ],
  'Ave': [
    'Agapornis',
    'Canario doméstico',
    'Diamante mandarín',
    'Diamante de Gould',
    'Ninfa / Cacatúa carolina',
    'Periquito australiano',
    'Periquito inglés',
    'Paloma doméstica',
    'Gallina doméstica',
    'Codorniz doméstica',
    'Pato doméstico',
    'Raza sin especificar',
  ],
  'Cobaya': [
    'Americana / Pelo corto',
    'Abisinia',
    'Peruana',
    'Silkie',
    'Texel',
    'Skinny',
    'Raza sin especificar',
  ],
  'Hurón': ['Doméstico / Pelo corto', 'Angora', 'Raza sin especificar'],
  'Pez': [
    'Betta',
    'Guppy',
    'Goldfish',
    'Molly',
    'Platy',
    'Tetra neón',
    'Corydora',
    'Escalar',
    'Raza sin especificar',
  ],
  'Tortuga': [
    'Tortuga de orejas rojas',
    'Tortuga de orejas amarillas',
    'Tortuga pintada',
    'Tortuga mapa',
    'Tortuga almizclera',
    'Tortuga de caparazón blando',
    'Tortuga acuática doméstica',
    'Tortuga terrestre doméstica',
    'Tortuga rusa',
    'Tortuga mediterránea',
    'Especie no identificada',
    'Raza sin especificar',
  ],
  'Iguana': ['Iguana verde', 'Iguana rinoceronte', 'Raza sin especificar'],
  'Erizo': ['Erizo pigmeo africano', 'Raza sin especificar'],
  'Otra especie': ['Raza sin especificar'],
};
const speciesIcons = <String, String>{
  'Perro': '🐶',
  'Gato': '🐱',
  'Conejo': '🐰',
  'Hámster': '🐹',
  'Ave': '🐦',
  'Cobaya': '🐹',
  'Hurón': '🦦',
  'Pez': '🐠',
  'Tortuga': '🐢',
  'Iguana': '🦎',
  'Erizo': '🦔',
  'Otra especie': '🐾',
};
String emojiFor(dynamic value) => speciesIcons[value] ?? '🐾';
const allPetSpecies = <String>[
  'Perro',
  'Gato',
  'Conejo',
  'Hámster',
  'Ave',
  'Cobaya',
  'Hurón',
  'Pez',
  'Tortuga',
  'Iguana',
  'Erizo',
  'Otra especie',
];

const defaultCareDefinitions = <Map<String, dynamic>>[
  {
    'id': 'feeding',
    'label': 'Alimentación',
    'icon': 'feeding',
    'species': allPetSpecies,
    'active': true,
  },
  {
    'id': 'water',
    'label': 'Agua',
    'icon': 'water',
    'species': [
      'Perro',
      'Gato',
      'Conejo',
      'Hámster',
      'Ave',
      'Cobaya',
      'Hurón',
      'Tortuga',
      'Iguana',
      'Erizo',
    ],
    'active': true,
  },
  {
    'id': 'walk',
    'label': 'Paseo / actividad',
    'icon': 'walk',
    'species': ['Perro'],
    'active': true,
  },
  {
    'id': 'hygiene',
    'label': 'Higiene',
    'icon': 'hygiene',
    'species': ['Perro', 'Gato'],
    'active': true,
  },
  {
    'id': 'habitat',
    'label': 'Limpieza del hábitat',
    'icon': 'habitat',
    'species': [
      'Conejo',
      'Hámster',
      'Ave',
      'Cobaya',
      'Hurón',
      'Tortuga',
      'Iguana',
      'Erizo',
    ],
    'active': true,
  },
  {
    'id': 'play',
    'label': 'Juego / enriquecimiento',
    'icon': 'play',
    'species': ['Gato', 'Conejo', 'Hámster', 'Ave', 'Cobaya', 'Hurón', 'Erizo'],
    'active': true,
  },
  {
    'id': 'aquarium',
    'label': 'Mantenimiento del acuario',
    'icon': 'aquarium',
    'species': ['Pez'],
    'active': true,
  },
  {
    'id': 'terrarium',
    'label': 'Revisión del terrario',
    'icon': 'habitat',
    'species': ['Iguana'],
    'active': true,
  },
  {
    'id': 'medicine',
    'label': 'Medicamento',
    'icon': 'medicine',
    'species': allPetSpecies,
    'active': true,
  },
  {
    'id': 'vet',
    'label': 'Veterinario',
    'icon': 'vet',
    'species': allPetSpecies,
    'active': true,
  },
];

const careIconChoices = <String, String>{
  'feeding': 'Alimentación',
  'water': 'Agua',
  'walk': 'Actividad',
  'hygiene': 'Higiene',
  'habitat': 'Hábitat / limpieza',
  'play': 'Juego',
  'aquarium': 'Acuario',
  'medicine': 'Medicamento',
  'vitamins': 'Vitaminas / suplemento',
  'vet': 'Veterinario',
  'check': 'General',
  'pets': 'Huellita / mascota',
};

String careLabel(String value) =>
    const {
      'feeding': 'Alimentación',
      'water': 'Agua',
      'walk': 'Paseo / actividad',
      'medicine': 'Medicamento',
      'hygiene': 'Higiene',
      'vet': 'Veterinario',
      'habitat': 'Limpieza del hábitat',
      'play': 'Juego / enriquecimiento',
      'aquarium': 'Mantenimiento del acuario',
      'vitamins': 'Vitaminas / suplemento',
    }[value] ??
    value;

IconData careIcon(String value) =>
    const {
      'feeding': Icons.restaurant,
      'water': Icons.water_drop,
      'walk': Icons.directions_walk,
      'medicine': Icons.medication,
      'hygiene': Icons.bathtub,
      'vet': Icons.health_and_safety,
      'habitat': Icons.cleaning_services,
      'play': Icons.toys,
      'aquarium': Icons.water,
      'vitamins': Icons.science,
      'check': Icons.check_circle,
      'pets': Icons.pets_rounded,
    }[value] ??
    Icons.check_circle;

String careTypeLabel(Map<String, dynamic> row) {
  final label = (row['label'] ?? '').toString().trim();
  if (label.isNotEmpty) return label;
  return careLabel((row['id'] ?? '').toString());
}

IconData careTypeIcon(Map<String, dynamic> row) =>
    careIcon((row['icon'] ?? row['id'] ?? 'check').toString());

List<Map<String, dynamic>> defaultCareForSpecies(String species) {
  return defaultCareDefinitions
      .where((item) {
        final raw = item['species'];
        return raw is List && raw.map((e) => e.toString()).contains(species);
      })
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String normalizeCareName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

bool careNameTaken(
  Iterable<Map<String, dynamic>> catalog,
  String candidate, {
  String? exceptId,
}) {
  final name = normalizeCareName(candidate);
  return name.isNotEmpty &&
      catalog.any(
        (item) =>
            (item['id'] ?? '').toString() != exceptId &&
            normalizeCareName(careTypeLabel(item)) == name,
      );
}

String effectiveReminderCareLabel(
  Map<String, dynamic> pet,
  String careId,
  String savedLabel,
) {
  final overrides = pet['careOverrides'];
  if (overrides is Map && overrides[careId] is Map) {
    final label = (overrides[careId]['label'] ?? '').toString().trim();
    if (label.isNotEmpty && label.length <= 50) {
      return label;
    }
  }
  final personal = pet['personalCareTypes'];
  if (personal is List) {
    for (final row in personal) {
      if (row is Map && (row['id'] ?? '').toString() == careId) {
        final label = (row['label'] ?? '').toString().trim();
        if (label.isNotEmpty && label.length <= 50) {
          return label;
        }
      }
    }
  }
  return savedLabel.trim().isNotEmpty ? savedLabel : careLabel(careId);
}

List<Map<String, dynamic>> mergedCareCatalogForPet(
  List<Map<String, dynamic>> catalog,
  Map<String, dynamic> pet,
) {
  final result = catalog.map((e) => Map<String, dynamic>.from(e)).toList();
  final ids = result.map((e) => (e['id'] ?? '').toString()).toSet();
  final rawOverrides = pet['careOverrides'];
  if (rawOverrides is Map) {
    for (final row in result) {
      final id = (row['id'] ?? '').toString();
      final custom = rawOverrides[id];
      if (custom is! Map) {
        continue;
      }
      final name = (custom['label'] ?? '').toString().trim();
      final icon = (custom['icon'] ?? '').toString();
      final originalLabel = careTypeLabel(row);
      final originalIcon = (row['icon'] ?? id).toString();
      var changed = false;
      if (name.isNotEmpty && name.length <= 45) {
        row['label'] = name;
        changed = true;
      }
      if (careIconChoices.containsKey(icon)) {
        row['icon'] = icon;
        changed = true;
      }
      if (changed) {
        row['originalLabel'] = originalLabel;
        row['originalIcon'] = originalIcon;
        row['userEdited'] = true;
      }
    }
  }
  final raw = pet['personalCareTypes'];
  if (raw is List) {
    for (final value in raw.take(30)) {
      if (value is! Map) {
        continue;
      }
      final id = (value['id'] ?? '').toString();
      final label = (value['label'] ?? '').toString().trim();
      if (!id.startsWith('personal_') ||
          ids.contains(id) ||
          label.isEmpty ||
          label.length > 45) {
        continue;
      }
      ids.add(id);
      final rawIcon = (value['icon'] ?? 'pets').toString();
      result.add({
        'id': id,
        'label': label,
        'icon': careIconChoices.containsKey(rawIcon) ? rawIcon : 'pets',
        'active': true,
        'personal': true,
      });
    }
  }
  return result;
}

Map<String, dynamic>? catalogCareById(
  List<Map<String, dynamic>> catalog,
  String id,
) {
  for (final item in catalog) {
    if ((item['id'] ?? '').toString() == id) return item;
  }
  return null;
}

String careEntryLabel(
  Map<String, dynamic> entry,
  List<Map<String, dynamic>> catalog,
) {
  final stored = (entry['label'] ?? '').toString().trim();
  if (stored.isNotEmpty) return stored;
  final id = (entry['type'] ?? '').toString();
  final found = catalogCareById(catalog, id);
  return found == null ? careLabel(id) : careTypeLabel(found);
}

IconData careEntryIcon(
  Map<String, dynamic> entry,
  List<Map<String, dynamic>> catalog,
) {
  final id = (entry['type'] ?? '').toString();
  final found = catalogCareById(catalog, id);
  return found == null ? careIcon(id) : careTypeIcon(found);
}

String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
DateTime? careDate(Map<String, dynamic> row) {
  final value = row['createdAt'];
  if (value is Timestamp) return value.toDate();
  return DateTime.tryParse((value ?? '').toString());
}

bool isToday(Map<String, dynamic> row) {
  final date = careDate(row);
  return date != null && dateKey(date) == dateKey(DateTime.now());
}

ImageProvider? petPhoto(Map<String, dynamic> pet) {
  final path = (pet['imagePath'] ?? '').toString();
  return path.isNotEmpty && File(path).existsSync()
      ? FileImage(File(path))
      : null;
}
