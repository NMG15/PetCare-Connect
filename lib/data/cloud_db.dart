part of '../main.dart';

Future<void> runPetDeletionBatches<T>({
  required Iterable<T> children,
  required T parent,
  required Future<void> Function(List<T>) commitBatch,
  int maxBatchSize = 400,
}) async {
  if (maxBatchSize < 1 || maxBatchSize > 400) {
    throw ArgumentError.value(maxBatchSize, 'maxBatchSize');
  }

  final references = <T>[...children, parent];

  for (var start = 0; start < references.length; start += maxBatchSize) {
    final current = references.skip(start).take(maxBatchSize).toList();
    await commitBatch(current);
  }
}

class CloudDb {
  CloudDb._() : _db = FirebaseFirestore.instance;
  CloudDb.forTesting(this._db);
  static final instance = CloudDb._();
  final FirebaseFirestore _db;

  String get uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No hay una sesión activa.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _pets =>
      _db.collection('users').doc(uid).collection('pets');

  Future<void> saveUserProfile(User user, {String? name}) async {
    await _db.collection('users').doc(user.uid).set({
      'name':
          (name?.trim().isNotEmpty ?? false)
              ? name!.trim()
              : (user.displayName ?? ''),
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> pets() async {
    final snap = await _pets.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<Map<String, dynamic>?> pet(String id) async {
    final doc = await _pets.doc(id).get();
    return doc.exists ? {'id': doc.id, ...doc.data()!} : null;
  }

  Future<String> addPet(Map<String, dynamic> values) async {
    final doc = await _pets.add({
      ...values,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updatePet(String id, Map<String, dynamic> values) async =>
      _pets.doc(id).set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> _deletePetWithCareAndReminders(
    DocumentReference<Map<String, dynamic>> petRef,
  ) async {
    final care = await petRef.collection('care').get();
    final reminders = await petRef.collection('reminders').get();

    await runPetDeletionBatches<DocumentReference<Map<String, dynamic>>>(
      children: [
        ...care.docs.map((doc) => doc.reference),
        ...reminders.docs.map((doc) => doc.reference),
      ],
      parent: petRef,
      commitBatch: (references) async {
        final batch = _db.batch();

        for (final reference in references) {
          batch.delete(reference);
        }

        await batch.commit();
      },
    );
  }

  Future<void> deletePet(String id) =>
      _deletePetWithCareAndReminders(_pets.doc(id));

  Future<List<Map<String, dynamic>>> care(String petId) async {
    final snap =
        await _pets
            .doc(petId)
            .collection('care')
            .orderBy('createdAt', descending: true)
            .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<String> addCare(String petId, Map<String, dynamic> careType) async {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final created = await _pets.doc(petId).collection('care').add({
      'type': careType['id'].toString(),
      'label': careTypeLabel(careType),
      'done': true,
      'time': time,
      'note': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return created.id;
  }

  Future<void> deleteCareRecord(String petId, String recordId) async {
    await _pets.doc(petId).collection('care').doc(recordId).delete();
  }

  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await _db.collection('admins').doc(user.uid).get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final snap =
        await _db
            .collection('users')
            .orderBy('updatedAt', descending: true)
            .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  CollectionReference<Map<String, dynamic>> adminPets(String userId) =>
      _db.collection('users').doc(userId).collection('pets');

  Future<List<Map<String, dynamic>>> adminUserPets(String userId) async {
    final snap =
        await adminPets(userId).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> adminSavePet(
    String userId, {
    String? petId,
    required Map<String, dynamic> values,
  }) async {
    if (petId == null) {
      await adminPets(userId).add({
        ...values,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await adminPets(userId).doc(petId).set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> adminDeletePet(String userId, String petId) =>
      _deletePetWithCareAndReminders(adminPets(userId).doc(petId));

  Future<List<Map<String, dynamic>>> adminCare(
    String userId,
    String petId,
  ) async {
    final snap =
        await adminPets(userId)
            .doc(petId)
            .collection('care')
            .orderBy('createdAt', descending: true)
            .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> adminAddCare(
    String userId,
    String petId,
    Map<String, dynamic> careType, {
    String note = '',
  }) async {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await adminPets(userId).doc(petId).collection('care').add({
      'type': careType['id'].toString(),
      'label': careTypeLabel(careType),
      'done': true,
      'time': time,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminUpdateCare(
    String userId,
    String petId,
    String careId,
    Map<String, dynamic> values,
  ) async => adminPets(userId)
      .doc(petId)
      .collection('care')
      .doc(careId)
      .set(values, SetOptions(merge: true));

  Future<void> adminDeleteCare(
    String userId,
    String petId,
    String careId,
  ) async =>
      adminPets(userId).doc(petId).collection('care').doc(careId).delete();

  CollectionReference<Map<String, dynamic>> get _careCatalog =>
      _db.collection('careCatalog');

  Future<List<Map<String, dynamic>>> careCatalog() async {
    final snap = await _careCatalog.get();
    final result = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    result.sort(
      (a, b) => careTypeLabel(
        a,
      ).toLowerCase().compareTo(careTypeLabel(b).toLowerCase()),
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> careCatalogForSpecies(
    String species,
  ) async {
    final all = await careCatalog();
    if (all.isEmpty) {
      final marker = await _db.collection('appConfig').doc('careCatalog').get();
      if (!marker.exists) {
        return defaultCareForSpecies(species);
      }
    }
    final visible =
        all.where((row) {
          final active = row['active'] != false;
          final rawSpecies = row['species'];
          final speciesList =
              rawSpecies is List
                  ? rawSpecies.map((e) => e.toString()).toList()
                  : <String>[];
          return active && speciesList.contains(species);
        }).toList();

    final configured = all.any((row) {
      final speciesList = row['species'];
      return speciesList is List && speciesList.contains(species);
    });
    if (!configured &&
        (species == 'Iguana' ||
            species == 'Erizo' ||
            species == 'Otra especie')) {
      return defaultCareForSpecies(species);
    }
    return visible;
  }

  Future<List<Map<String, dynamic>>> careCatalogForPet(
    String species,
    Map<String, dynamic> pet,
  ) async {
    final base = await careCatalogForSpecies(species);
    return mergedCareCatalogForPet(base, pet);
  }

  Future<void> ensureDefaultCareCatalog() async {
    final marker = _db.collection('appConfig').doc('careCatalog');
    final markerDoc = await marker.get();
    if (markerDoc.exists) return;

    final existing = await _careCatalog.limit(1).get();
    if (existing.docs.isNotEmpty) {
      await marker.set({
        'initialized': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final batch = _db.batch();
    for (final item in defaultCareDefinitions) {
      final id = item['id'].toString();
      batch.set(_careCatalog.doc(id), {
        'label': item['label'],
        'icon': item['icon'],
        'species': item['species'],
        'active': item['active'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(marker, {
      'initialized': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> adminSaveCareType({
    String? careId,
    required String label,
    required String description,
    required String icon,
    required List<String> species,
    required bool active,
  }) async {
    final values = <String, dynamic>{
      'label': label.trim(),
      'description': description.trim(),
      'icon': icon,
      'species': species,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (careId == null) {
      await _careCatalog.add({
        ...values,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _careCatalog.doc(careId).set(values, SetOptions(merge: true));
    }
  }

  Future<void> adminDeleteCareType(String careId) async =>
      _careCatalog.doc(careId).delete();

  Future<void> adminUpdateUserName(String userId, String name) async =>
      _db.collection('users').doc(userId).set({
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
