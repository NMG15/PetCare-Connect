import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'petcare_care_features.dart';
import 'petcare_cloud_messaging.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const green = Color(0xFF2F8F6B);
const cream = Color(0xFFF8F6F1);
const orange = Color(0xFFF2A65A);
const ink = Color(0xFF193B32);
const pale = Color(0xFFEAF5EF);


/// Mantiene los valores anteriores guardados en Firestore y corrige el singular.
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

/// Permite combinar varios colores y mantener también colores personalizados.
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
          const Text('Colores de tu mascota', style: TextStyle(
              color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Selecciona uno o varios colores. También puedes escribir otro tono.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 18),
          Wrap(spacing: 7, runSpacing: 6,
            children: petColorOptions.map((value) => FilterChip(
              label: Text(value),
              selected: selected.contains(value),
              onSelected: (yes) => setState(() {
                if (yes) { selected.add(value); } else { selected.remove(value); }
              }),
            )).toList(),
          ),
          const SizedBox(height: 14),
          TextField(controller: custom, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Otro color o combinación (opcional)',
              hintText: 'Ej. café claro con blanco',
              prefixIcon: Icon(Icons.palette_outlined),
            )),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, height: 52,
            child: FilledButton.icon(
              onPressed: () {
                final result = [...petColorOptions.where(selected.contains),
                  if (custom.text.trim().isNotEmpty) custom.text.trim()];
                if (result.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Elige o escribe al menos un color.')));
                  return;
                }
                Navigator.pop(context, result.join(' con '));
              },
              icon: const Icon(Icons.check),
              label: const Text('Guardar colores'),
            ),
          ),
        ]),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  registerPetCareCloudBackgroundHandler();
  await GoogleSignIn.instance.initialize();
  try {
    await PetCareAlerts.instance.init();
  } catch (_) {
    // Si el teléfono no expone su zona horaria, la app puede abrirse.
    // La pantalla de recordatorios mostrará el error al programar.
  }
  try {
    await PetCareCloudMessaging.instance.init();
  } catch (_) {
    // FCM se volverá a intentar cuando el usuario inicie sesión.
  }
  runApp(const PetCareApp());
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PetCare Connect',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          scaffoldBackgroundColor: cream,
          appBarTheme: const AppBarTheme(
            backgroundColor: cream, foregroundColor: ink,
            elevation: 0, centerTitle: false,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: green, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
          cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22))),
        ),
        home: const AuthGate(),
      );
}

class CloudDb {
  CloudDb._();
  static final instance = CloudDb._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No hay una sesión activa.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _pets =>
      _db.collection('users').doc(uid).collection('pets');

  Future<void> saveUserProfile(User user, {String? name}) async {
    await _db.collection('users').doc(user.uid).set({
      'name': (name?.trim().isNotEmpty ?? false) ? name!.trim() : (user.displayName ?? ''),
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
      _pets.doc(id).set({...values, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

  Future<void> deletePet(String id) async {
    final care = await _pets.doc(id).collection('care').get();
    final batch = _db.batch();
    for (final doc in care.docs) {
      batch.delete(doc.reference);
    }
    final reminders = await _pets.doc(id).collection('reminders').get();
    for (final doc in reminders.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_pets.doc(id));
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> care(String petId) async {
    final snap = await _pets.doc(petId).collection('care').orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> addCare(
      String petId, Map<String, dynamic> careType) async {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _pets.doc(petId).collection('care').add({
      'type': careType['id'].toString(),
      'label': careTypeLabel(careType),
      'done': true,
      'time': time,
      'note': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await _db.collection('admins').doc(user.uid).get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final snap = await _db.collection('users').orderBy('updatedAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  CollectionReference<Map<String, dynamic>> adminPets(String userId) =>
      _db.collection('users').doc(userId).collection('pets');

  Future<List<Map<String, dynamic>>> adminUserPets(String userId) async {
    final snap = await adminPets(userId).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> adminSavePet(String userId, {String? petId, required Map<String, dynamic> values}) async {
    if (petId == null) {
      await adminPets(userId).add({...values, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await adminPets(userId).doc(petId).set({...values, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
  }

  Future<void> adminDeletePet(String userId, String petId) async {
    final care = await adminPets(userId).doc(petId).collection('care').get();
    final batch = _db.batch();
    for (final doc in care.docs) { batch.delete(doc.reference); }
    final reminders =
        await adminPets(userId).doc(petId).collection('reminders').get();
    for (final doc in reminders.docs) { batch.delete(doc.reference); }
    batch.delete(adminPets(userId).doc(petId));
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> adminCare(String userId, String petId) async {
    final snap = await adminPets(userId).doc(petId).collection('care').orderBy('createdAt', descending: true).get();
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
      Map<String, dynamic> values) async =>
      adminPets(userId)
          .doc(petId)
          .collection('care')
          .doc(careId)
          .set(values, SetOptions(merge: true));

  Future<void> adminDeleteCare(
          String userId, String petId, String careId) async =>
      adminPets(userId).doc(petId).collection('care').doc(careId).delete();

  CollectionReference<Map<String, dynamic>> get _careCatalog =>
      _db.collection('careCatalog');

  Future<List<Map<String, dynamic>>> careCatalog() async {
    final snap = await _careCatalog.get();
    final result =
        snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    result.sort((a, b) => careTypeLabel(a)
        .toLowerCase()
        .compareTo(careTypeLabel(b).toLowerCase()));
    return result;
  }

  Future<List<Map<String, dynamic>>> careCatalogForSpecies(
      String species) async {
    final all = await careCatalog();
    if (all.isEmpty) {
      final marker =
          await _db.collection('appConfig').doc('careCatalog').get();
      if (!marker.exists) {
        return defaultCareForSpecies(species);
      }
    }
    return all.where((row) {
      final active = row['active'] != false;
      final rawSpecies = row['species'];
      final speciesList = rawSpecies is List
          ? rawSpecies.map((e) => e.toString()).toList()
          : <String>[];
      return active && speciesList.contains(species);
    }).toList();
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
      await _careCatalog
          .doc(careId)
          .set(values, SetOptions(merge: true));
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data == null ? const WelcomePage() : const HomePage();
        },
      );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                const Spacer(),
                Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        color: green.withValues(alpha: .12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.pets, size: 66, color: green)),
                const SizedBox(height: 28),
                const Text('PetCare Connect',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183B32))),
                const SizedBox(height: 12),
                const Text('Todo el cuidado de tus mascotas, en un solo lugar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: Colors.black54)),
                const Spacer(),
                SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AuthPage(login: true))),
                        child: const Text('Iniciar sesión'))),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AuthPage(login: false))),
                        child: const Text('Crear cuenta'))),
              ]))));
}

class AuthPage extends StatefulWidget {
  final bool login;
  const AuthPage({super.key, required this.login});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
  bool showPassword = false;

  void msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> emailAuth() async {
    if (email.text.trim().isEmpty || pass.text.length < 8 || (!widget.login && name.text.trim().isEmpty)) {
      msg('Completa los datos. La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    setState(() => busy = true);
    try {
      UserCredential credential;
      if (widget.login) {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: pass.text,
        );
      } else {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: pass.text,
        );
        await credential.user?.updateDisplayName(name.text.trim());
        // El correo de verificación es parte de Firebase Authentication.
        // No bloquear la cuenta si el proveedor de correo está momentáneamente indisponible.
        try {
          await credential.user?.sendEmailVerification();
        } on FirebaseAuthException {
          // La pantalla principal permite solicitar un nuevo correo.
        }
      }
      if (credential.user != null) {
        await CloudDb.instance.saveUserProfile(credential.user!, name: widget.login ? null : name.text);
      }
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'Ese correo ya está registrado.',
        'invalid-email' => 'El correo electrónico no es válido.',
        'weak-password' => 'La contraseña es demasiado débil.',
        'invalid-credential' => 'Correo o contraseña incorrectos.',
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'wrong-password' => 'Correo o contraseña incorrectos.',
        _ => 'No se pudo iniciar sesión. ${e.message ?? ''}',
      };
      if (mounted) msg(message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> googleAuth() async {
    setState(() => busy = true);
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      if (result.user != null) await CloudDb.instance.saveUserProfile(result.user!);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on GoogleSignInException catch (e) {
      if (mounted && e.code != GoogleSignInExceptionCode.canceled) msg('No se pudo iniciar sesión con Google.');
    } on FirebaseAuthException catch (e) {
      if (mounted) msg('Firebase no pudo iniciar sesión con Google: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    final value = email.text.trim();
    if (value.isEmpty) { msg('Escribe tu correo primero.'); return; }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: value);
      if (mounted) msg('Te enviamos un correo para restablecer tu contraseña.');
    } on FirebaseAuthException catch (e) {
      if (mounted) msg(e.message ?? 'No se pudo enviar el correo.');
    }
  }

  @override
  void dispose() { name.dispose(); email.dispose(); pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.pets, color: green, size: 52),
        const SizedBox(height: 18),
        Text(widget.login ? 'Bienvenido de nuevo' : 'Crea tu cuenta', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.login ? 'Tus mascotas se sincronizan de forma segura en la nube.' : 'Crea una cuenta para guardar tus mascotas en la nube.', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 30),
        if (!widget.login) ...[
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Tu nombre', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
        ],
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 14),
        TextField(
          controller: pass,
          obscureText: !showPassword,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
              onPressed: () => setState(() => showPassword = !showPassword),
              icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
          ),
        ),
        if (widget.login) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : resetPassword, child: const Text('¿Olvidaste tu contraseña?'))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 55, child: FilledButton(onPressed: busy ? null : emailAuth, child: Text(busy ? 'Espera...' : widget.login ? 'Iniciar sesión' : 'Crear cuenta'))),
        const SizedBox(height: 18),
        const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o')), Expanded(child: Divider())]),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, height: 55, child: OutlinedButton.icon(onPressed: busy ? null : googleAuth, icon: const Icon(Icons.account_circle_outlined), label: const Text('Continuar con Google'))),
      ]),
    ),
  );
}

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
    'Otra / No sé',
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
    'Yorkshire Terrier'
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
    'Otra / No sé',
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
    'Turco Van'
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
    'Otra / No sé',
    'Rex'
  ],
  'Hámster': [
    'Sirio / Dorado',
    'Ruso de Campbell',
    'Ruso de invierno',
    'Roborovski',
    'Chino',
    'Otro / No sé'
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
    'Otra ave doméstica / No sé'
  ],
  'Cobaya': [
    'Americana / Pelo corto',
    'Abisinia',
    'Peruana',
    'Silkie',
    'Texel',
    'Skinny',
    'Mestiza / Otra'
  ],
  'Hurón': ['Doméstico / Pelo corto', 'Angora', 'Otro / No sé'],
  'Pez': [
    'Betta',
    'Guppy',
    'Goldfish',
    'Molly',
    'Platy',
    'Tetra neón',
    'Corydora',
    'Escalar',
    'Otro pez ornamental'
  ],
  'Tortuga': [
    'Tortuga acuática doméstica',
    'Tortuga terrestre doméstica',
    'Otra / No sé'
  ],
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
  'Tortuga': '🐢'
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
      'Tortuga'
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
    'species': ['Conejo', 'Hámster', 'Ave', 'Cobaya', 'Hurón', 'Tortuga'],
    'active': true,
  },
  {
    'id': 'play',
    'label': 'Juego / enriquecimiento',
    'icon': 'play',
    'species': ['Gato', 'Conejo', 'Hámster', 'Ave', 'Cobaya', 'Hurón'],
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

Map<String, dynamic>? catalogCareById(
    List<Map<String, dynamic>> catalog, String id) {
  for (final item in catalog) {
    if ((item['id'] ?? '').toString() == id) return item;
  }
  return null;
}

String careEntryLabel(
    Map<String, dynamic> entry, List<Map<String, dynamic>> catalog) {
  final stored = (entry['label'] ?? '').toString().trim();
  if (stored.isNotEmpty) return stored;
  final id = (entry['type'] ?? '').toString();
  final found = catalogCareById(catalog, id);
  return found == null ? careLabel(id) : careTypeLabel(found);
}

IconData careEntryIcon(
    Map<String, dynamic> entry, List<Map<String, dynamic>> catalog) {
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> pets = [];
  bool loading = true;
  bool admin = false;
  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await CloudDb.instance.saveUserProfile(currentUser);
      try {
        await PetCareCloudMessaging.instance.registerForCurrentUser();
      } catch (_) {
        // La app sigue funcionando si FCM no está disponible temporalmente.
      }
    }
    final result = await CloudDb.instance.pets();
    final isAdmin = await CloudDb.instance.isAdmin();
    if (mounted) {
      setState(() {
        pets = result;
        admin = isAdmin;
        loading = false;
      });
    }
    if (currentUser != null) {
      try {
        await PetCareAlerts.instance.syncForUser(currentUser.uid);
      } catch (_) {
        // La app puede seguir funcionando; los avisos se reintentan al reabrirla.
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
                title: const Text('¿Eliminar mascota?'),
                content: Text(
                    'Se eliminarán ${pet['name']} y todos sus cuidados registrados. Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Eliminar'))
                ]));
    if (ok == true) {
      await CloudDb.instance.deletePet(pet['id'].toString());
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('PetCare Connect',
              style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
          actions: [
            if (admin)
              IconButton(
                  tooltip: 'Panel de administrador',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminPage())),
                  icon: const Icon(Icons.admin_panel_settings_outlined)),
            IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  await PetCareCloudMessaging.instance.unregisterCurrentUser();
                  await PetCareAlerts.instance.cancelAll();
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded))
          ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: add,
          icon: const Icon(Icons.add),
          label: const Text('Nueva mascota')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  children: [
                    Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(colors: [ink, green]),
                            borderRadius: BorderRadius.circular(28)),
                        child: const Column(
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
                    const SizedBox(height: 14),
                    if (FirebaseAuth.instance.currentUser?.emailVerified == false &&
                        FirebaseAuth.instance.currentUser?.providerData.any(
                          (provider) => provider.providerId == 'password',
                        ) == true)
                      Card(
                        color: const Color(0xFFFFF4E5),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Icon(Icons.email_outlined, color: ink),
                                SizedBox(width: 9),
                                Expanded(child: Text('Confirma tu correo',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: ink))),
                              ]),
                              const SizedBox(height: 7),
                              const Text('Te enviamos un enlace de verificación. Revisa tu bandeja y spam.'),
                              Wrap(spacing: 8, children: [
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Correo enviado. Revisa tu bandeja y spam.')));
                                    } on FirebaseAuthException catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('No se pudo reenviar el correo: ${e.message ?? e.code}')));
                                    }
                                  },
                                  child: const Text('Reenviar correo'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.currentUser?.reload();
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text('Ya verifiqué'),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Row(children: [
                      const Expanded(
                          child: Text('Mis mascotas',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ink))),
                      Text('${pets.length} registradas',
                          style: const TextStyle(color: green))
                    ]),
                    const SizedBox(height: 14),
                    if (pets.isEmpty)
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(children: [
                                const Icon(Icons.pets, size: 58, color: green),
                                const SizedBox(height: 12),
                                const Text('Aún no tienes mascotas',
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text(
                                    'Agrega una mascota y personaliza su perfil.',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton(
                                    onPressed: add,
                                    child: const Text(
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
                                        backgroundColor: pale,
                                        backgroundImage: petPhoto(pet),
                                        child: petPhoto(pet) == null
                                            ? Text(emojiFor(pet['species']),
                                                style: const TextStyle(
                                                    fontSize: 32))
                                            : null),
                                    const SizedBox(width: 14),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text('${pet['name']}',
                                              style: const TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                  color: ink)),
                                          const SizedBox(height: 4),
                                          Text(
                                              '${pet['species']} · ${pet['breed']}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.black54))
                                        ])),
                                    PopupMenuButton<String>(
                                        tooltip: 'Opciones',
                                        onSelected: (v) async {
                                          if (v == 'delete') {
                                            await delete(pet);
                                          } else if (v == 'edit') {
                                            if (!mounted) return;
                                            await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => PetEditor(existing: pet)));
                                            if (mounted) {
                                              await reload();
                                            }
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Editar perfil')),
                                              PopupMenuItem(
                                                  value: 'delete',
                                                  child:
                                                      Text('Eliminar mascota'))
                                            ]),
                                    const Icon(Icons.chevron_right,
                                        color: green)
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
          const SnackBar(content: Text('Escribe el nombre de tu mascota.')));
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
            const SnackBar(content: Text('No se pudo guardar la mascota.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              widget.existing == null ? 'Nueva mascota' : 'Editar mascota')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
          children: [
            Center(
                child: InkWell(
                    onTap: choosePhoto,
                    borderRadius: BorderRadius.circular(70),
                    child: Stack(children: [
                      CircleAvatar(
                          radius: 64,
                          backgroundColor: pale,
                          backgroundImage:
                              image != null && File(image!).existsSync()
                                  ? FileImage(File(image!))
                                  : null,
                          child: image == null || !File(image!).existsSync()
                              ? Text(emojiFor(species),
                                  style: const TextStyle(fontSize: 55))
                              : null),
                      const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.camera_alt_outlined)))
                    ]))),
            const SizedBox(height: 9),
            const Center(
                child: Text('Toca para elegir una fotografía',
                    style: TextStyle(color: Colors.black54))),
            const SizedBox(height: 25),
            const Text('Datos principales',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
            const SizedBox(height: 12),
            TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nombre de la mascota',
                    prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: species,
                decoration: const InputDecoration(
                    labelText: 'Especie', prefixIcon: Icon(Icons.pets)),
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
            const SizedBox(height: 12),
            ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.search, color: green),
                title: const Text('Raza / categoría'),
                subtitle:
                    Text(breed, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: selectBreed),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue:
                    ['Macho', 'Hembra', 'No especificado'].contains(sex)
                        ? sex
                        : 'No especificado',
                decoration: const InputDecoration(labelText: 'Sexo'),
                items: ['Macho', 'Hembra', 'No especificado']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => sex = v);
                }),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          labelText: 'Edad',
                          hintText: 'Ej. 2',
                          suffixText: age.text.trim() == '1' ? 'año' : 'años'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: weight,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'))
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Peso',
                          hintText: 'Ej. 15',
                          suffixText: 'kg')))
            ]),
            const SizedBox(height: 12),
            Card(child: ListTile(
              leading: const Icon(Icons.palette_outlined, color: green),
              title: const Text('Colores'),
              subtitle: Text(color.text.trim().isEmpty
                  ? 'Selecciona uno o varios colores'
                  : color.text.trim()),
              trailing: const Icon(Icons.expand_more),
              onTap: () async {
                final value = await choosePetColors(context, color.text);
                if (value != null && mounted) setState(() => color.text = value);
              },
            )),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('pelaje-$species'),
              isExpanded: true,
              initialValue: customCoat
                  ? 'Otro (especificar)'
                  : petCoatOptions(species).contains(coat.text) ? coat.text : null,
              decoration: InputDecoration(
                labelText: species == 'Ave' ? 'Plumaje'
                    : species == 'Pez' || species == 'Tortuga'
                        ? 'Características' : 'Pelaje',
                prefixIcon: const Icon(Icons.tune),
              ),
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
              const SizedBox(height: 10),
              TextField(controller: coat,
                  decoration: const InputDecoration(
                    labelText: 'Describe el pelaje o característica',
                    hintText: 'Ej. corto y rizado',
                  )),
            ],
            const SizedBox(height: 24),
            SizedBox(
                height: 54,
                child: FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: const Icon(Icons.check),
                    label: Text(saving
                        ? 'Guardando...'
                        : widget.existing == null
                            ? 'Guardar mascota'
                            : 'Guardar cambios')))
          ]));
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
                                style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: ink)),
                            const SizedBox(height: 12),
                            TextField(
                                autofocus: true,
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: 'Buscar raza o categoría'),
                                onChanged: (v) => setState(() => search = v))
                          ])),
                  const SizedBox(height: 8),
                  Expanded(
                      child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final value = list[i];
                            return ListTile(
                                title: Text(value),
                                trailing: value == widget.selected
                                    ? const Icon(Icons.check_circle,
                                        color: green)
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
      return const Scaffold(
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
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            icon: const Icon(Icons.edit_outlined),
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
                gradient: const LinearGradient(colors: [ink, green]),
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
                            style: const TextStyle(fontSize: 47),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${current['name']}',
                    style: const TextStyle(
                      fontSize: 27,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${current['species']} · ${current['breed']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cuidados de hoy',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completed de ${careTypes.length} tipos de cuidado registrados',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: careTypes.isEmpty
                          ? 0
                          : completed / careTypes.length,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(12),
                      backgroundColor: pale,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Organiza sus cuidados',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
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
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Horarios y recordatorios'),
                    ),
                    const SizedBox(height: 7),
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
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Historial: semana, mes y años'),
                    ),
                    const SizedBox(height: 7),
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
                      icon: const Icon(Icons.tune_outlined),
                      label: const Text('Elegir qué cuidados mostrar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (careTypes.isEmpty)
              const Card(
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
                                        done ? pale : const Color(0xFFFFF1E0),
                                    child: Icon(
                                      done ? Icons.check : careTypeIcon(type),
                                      color: done ? green : orange,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    careTypeLabel(type),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if ((type['description'] ?? '').toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      type['description'].toString(),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    done
                                        ? 'Registrado hoy · repetir'
                                        : 'Registrar cuidado',
                                    style: TextStyle(
                                      color: done ? green : Colors.black54,
                                      fontSize: 12,
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
            const SizedBox(height: 22),
            const Text(
              'Información',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 22),
            const Text(
              'Últimos cuidados registrados',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Card(
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
                      backgroundColor: pale,
                      child: Icon(
                        careEntryIcon(entry, careTypes),
                        color: green,
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
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valueText.isEmpty ? 'No registrado' : valueText,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}


class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool loading = true;
  List<Map<String, dynamic>> users = [];
  int petsCount = 0;
  int careTypesCount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final ok = await CloudDb.instance.isAdmin();
    if (!ok) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      await CloudDb.instance.ensureDefaultCareCatalog();
    } catch (_) {
      // El panel puede seguir abriendo aunque Firebase esté momentáneamente lento.
    }

    try {
      final data = await CloudDb.instance.adminUsers();
      final catalog = await CloudDb.instance.careCatalog();

      var totalPets = 0;
      for (final user in data) {
        try {
          final userPets =
              await CloudDb.instance.adminUserPets(user['id'].toString());
          totalPets += userPets.length;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          users = data;
          petsCount = totalPets;
          careTypesCount = catalog.length;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo cargar el panel. Revisa la conexión e inténtalo de nuevo.',
            ),
          ),
        );
      }
    }
  }

  Widget summaryBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: green,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget adminOption({
    required String title,
    required String description,
    required String buttonText,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: pale,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: green),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ink, green],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panel del administrador',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Aquí administras usuarios, mascotas y las opciones de cuidado que aparecen en PetCare.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      summaryBox('${users.length}', 'Usuarios'),
                      const SizedBox(width: 8),
                      summaryBox('$petsCount', 'Mascotas'),
                      const SizedBox(width: 8),
                      summaryBox('$careTypesCount', 'Cuidados'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¿Qué quieres administrar?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  adminOption(
                    title: 'Usuarios y mascotas',
                    description:
                        'Entra a un usuario para ver sus mascotas, editar sus datos, agregar mascotas y revisar sus cuidados.',
                    buttonText: 'ABRIR USUARIOS Y MASCOTAS',
                    icon: Icons.people_alt_outlined,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUsersListPage(users: users),
                        ),
                      );
                      await load();
                    },
                  ),
                  const SizedBox(height: 10),
                  adminOption(
                    title: 'Tipos de cuidado',
                    description:
                        'Decide qué cuidados pueden registrar los usuarios. Crear uno nuevo NO cambia los cuidados que ya existen.',
                    buttonText: 'ABRIR TIPOS DE CUIDADO',
                    icon: Icons.checklist_rounded,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminCareCatalogPage(),
                        ),
                      );
                      await load();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class AdminUsersListPage extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const AdminUsersListPage({super.key, required this.users});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Usuarios y mascotas')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Selecciona un usuario para ver sus mascotas.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            if (users.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Todavía no hay usuarios registrados.'),
                ),
              ),
            ...users.map((u) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: pale,
                        child: Icon(Icons.person_outline, color: green)),
                    title: Text((u['name'] ?? '').toString().isEmpty
                        ? 'Usuario'
                        : u['name'].toString()),
                    subtitle: Text((u['email'] ?? '').toString()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AdminUserPage(user: u))),
                  ),
                )),
          ],
        ),
      );
}

class AdminUserPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserPage({
    super.key,
    required this.user,
  });

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  bool loading = true;
  List<Map<String, dynamic>> pets = [];

  String get userId => widget.user['id'].toString();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await CloudDb.instance.adminUserPets(userId);
    if (mounted) {
      setState(() {
        pets = data;
        loading = false;
      });
    }
  }

  Future<void> editUser() async {
    final changed = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserEditorPage(user: widget.user),
      ),
    );
    if (changed != null && mounted) {
      setState(() => widget.user['name'] = changed);
    }
  }

  Future<void> editPet([Map<String, dynamic>? pet]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPetEditorPage(
          userId: userId,
          existing: pet,
        ),
      ),
    );
    if (changed == true) {
      await load();
    }
  }

  Future<void> openPet(Map<String, dynamic> pet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPetPage(
          userId: userId,
          pet: pet,
        ),
      ),
    );
    await load();
  }

  Future<void> removePet(Map<String, dynamic> pet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
          '¿Eliminar ${pet['name']} y todos sus cuidados registrados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar mascota'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await CloudDb.instance.adminDeletePet(
        userId,
        pet['id'].toString(),
      );
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = (widget.user['name'] ?? '').toString().trim();
    final email = (widget.user['email'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          userName.isEmpty ? 'Usuario' : userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editPet(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar mascota'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos del usuario',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userName.isEmpty ? 'Sin nombre registrado' : userName,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: editUser,
                            child: const Text('Editar datos del usuario'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mascotas de este usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ),
                    Text(
                      '${pets.length}',
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pets.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Este usuario todavía no tiene mascotas.'),
                      ),
                    ),
                  ),
                ...pets.map((pet) {
                  final petName =
                      (pet['name'] ?? 'Mascota').toString();
                  final species = (pet['species'] ?? '').toString();
                  final breed = (pet['breed'] ?? '').toString();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: pale,
                                child: Text(emojiFor(species)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      petName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      breed.isEmpty
                                          ? species
                                          : '$species · $breed',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: () => openPet(pet),
                              child: const Text('Ver y administrar cuidados'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => editPet(pet),
                                  child: const Text('Editar mascota'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => removePet(pet),
                                  child: const Text('Eliminar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class AdminUserEditorPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminUserEditorPage({super.key, required this.user});

  @override
  State<AdminUserEditorPage> createState() => _AdminUserEditorPageState();
}

class _AdminUserEditorPageState extends State<AdminUserEditorPage> {
  final name = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name.text = (widget.user['name'] ?? '').toString();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = name.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await CloudDb.instance.adminUpdateUserName(
        widget.user['id'].toString(),
        value,
      );
      if (mounted) Navigator.pop(context, value);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar el usuario.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Editar usuario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: (widget.user['email'] ?? '').toString(),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
                helperText:
                    'El correo de acceso no se modifica desde el panel.',
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: Text(saving ? 'Guardando...' : 'Guardar'),
              ),
            ),
          ],
        ),
      );
}


class AdminPetEditorPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existing;

  const AdminPetEditorPage({
    super.key,
    required this.userId,
    this.existing,
  });

  @override
  State<AdminPetEditorPage> createState() => _AdminPetEditorPageState();
}

class _AdminPetEditorPageState extends State<AdminPetEditorPage> {
  late String species;
  late String breed;
  late String sex;

  bool saving = false;
  bool customCoat = false;

  final name = TextEditingController();
  final age = TextEditingController();
  final weight = TextEditingController();
  final color = TextEditingController();
  final coat = TextEditingController();

  @override
  void initState() {
    super.initState();

    final old = widget.existing;

    species = (old?['species'] ?? 'Perro').toString();
    if (!speciesCatalog.containsKey(species)) {
      species = 'Perro';
    }

    final oldBreed = (old?['breed'] ?? '').toString();
    breed = oldBreed.isNotEmpty
        ? oldBreed
        : speciesCatalog[species]!.first;

    sex = (old?['sex'] ?? 'No especificado').toString();
    if (!['Macho', 'Hembra', 'No especificado'].contains(sex)) {
      sex = 'No especificado';
    }

    name.text = (old?['name'] ?? '').toString();
    age.text = (old?['age'] ?? '').toString();
    weight.text = (old?['weight'] ?? '').toString();
    color.text = (old?['color'] ?? '').toString();
    coat.text = (old?['coat'] ?? '').toString();
    customCoat = coat.text.isNotEmpty && !petCoatOptions(species).contains(coat.text);
  }

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    weight.dispose();
    color.dispose();
    coat.dispose();
    super.dispose();
  }

  Future<void> selectBreed() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BreedSelector(
        species: species,
        selected: breed,
      ),
    );

    if (chosen != null && mounted) {
      setState(() => breed = chosen);
    }
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe el nombre de la mascota.'),
        ),
      );
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
        if (widget.existing == null) 'imagePath': '',
      };

      await CloudDb.instance.adminSavePet(
        widget.userId,
        petId: widget.existing?['id']?.toString(),
        values: values,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la mascota.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coatLabel = species == 'Ave'
        ? 'Plumaje'
        : species == 'Pez' || species == 'Tortuga'
            ? 'Características'
            : 'Pelaje';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Agregar mascota'
              : 'Editar mascota',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          const Text(
            'Datos de la mascota',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: species,
            decoration: const InputDecoration(
              labelText: 'Especie',
              prefixIcon: Icon(Icons.pets),
            ),
            items: speciesCatalog.keys
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('${emojiFor(value)}  $value'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  species = value;
                  breed = speciesCatalog[value]!.first;
                  coat.clear();
                  customCoat = false;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.search, color: green),
            title: const Text('Raza / categoría'),
            subtitle: Text(
              breed,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: selectBreed,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: sex,
            decoration: const InputDecoration(
              labelText: 'Sexo',
            ),
            items: ['Macho', 'Hembra', 'No especificado']
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => sex = value);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: age,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Edad',
                    hintText: 'Ej. 2',
                    suffixText: age.text.trim() == '1' ? 'año' : 'años',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Peso',
                    hintText: 'Ej. 15',
                    suffixText: 'kg',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.palette_outlined, color: green),
            title: const Text('Colores'),
            subtitle: Text(color.text.trim().isEmpty
                ? 'Selecciona uno o varios colores'
                : color.text.trim()),
            trailing: const Icon(Icons.expand_more),
            onTap: () async {
              final value = await choosePetColors(context, color.text);
              if (value != null && mounted) setState(() => color.text = value);
            },
          )),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('admin-pelaje-$species'),
            isExpanded: true,
            initialValue: customCoat ? 'Otro (especificar)'
                : petCoatOptions(species).contains(coat.text) ? coat.text : null,
            decoration: InputDecoration(labelText: coatLabel,
                prefixIcon: const Icon(Icons.tune)),
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
            const SizedBox(height: 10),
            TextField(controller: coat,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Describe el pelaje o característica',
                hintText: 'Ej. corto y rizado',
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.check),
              label: Text(
                saving
                    ? 'Guardando...'
                    : widget.existing == null
                        ? 'Agregar mascota'
                        : 'Guardar cambios',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCareCatalogPage extends StatefulWidget {
  const AdminCareCatalogPage({super.key});

  @override
  State<AdminCareCatalogPage> createState() =>
      _AdminCareCatalogPageState();
}

class _AdminCareCatalogPageState extends State<AdminCareCatalogPage> {
  bool loading = true;
  List<Map<String, dynamic>> items = [];
  String speciesFilter = 'Todas';
  String statusFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await CloudDb.instance.careCatalog();
      if (mounted) {
        setState(() {
          items = data;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudieron cargar los tipos de cuidado. Revisa la conexión.',
            ),
          ),
        );
      }
    }
  }

  Future<void> createNew() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminCareTypeEditorPage(),
      ),
    );
    if (changed == true) {
      await load();
    }
  }

  Future<void> edit(Map<String, dynamic> row) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCareTypeEditorPage(existing: row),
      ),
    );
    if (changed == true) {
      await load();
    }
  }

  Future<void> duplicate(Map<String, dynamic> row) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCareTypeEditorPage(copyFrom: row),
      ),
    );
    if (changed == true) {
      await load();
    }
  }

  Future<void> changeActive(Map<String, dynamic> row) async {
    final active = row['active'] != false;

    try {
      await CloudDb.instance.adminSaveCareType(
        careId: row['id'].toString(),
        label: careTypeLabel(row),
        description: (row['description'] ?? '').toString(),
        icon: (row['icon'] ?? 'check').toString(),
        species: (row['species'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        active: !active,
      );
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cambiar la visibilidad del cuidado.'),
          ),
        );
      }
    }
  }

  Future<void> remove(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar tipo de cuidado'),
        content: Text(
          '¿Eliminar «${careTypeLabel(row)}»?\n\n'
          'Esta opción dejará de aparecer para los usuarios. '
          'Los registros que ya hicieron permanecen en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await CloudDb.instance.adminDeleteCareType(
        row['id'].toString(),
      );
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar el tipo de cuidado.'),
          ),
        );
      }
    }
  }

  String speciesText(Map<String, dynamic> row) {
    final raw = row['species'];
    final list = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];

    if (list.length == allPetSpecies.length) {
      return 'Todas las especies';
    }
    if (list.isEmpty) {
      return 'Sin especies seleccionadas';
    }
    if (list.length <= 3) {
      return list.join(', ');
    }
    return '${list.take(3).join(', ')} y ${list.length - 3} más';
  }

  @override
  Widget build(BuildContext context) {
    final shown = items.where((row) {
      final active = row['active'] != false;

      if (speciesFilter != 'Todas') {
        final species = row['species'];
        if (species is! List || !species.contains(speciesFilter)) {
          return false;
        }
      }

      if (statusFilter == 'Visibles' && !active) {
        return false;
      }
      if (statusFilter == 'Ocultos' && active) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tipos de cuidado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
                children: [
                  Card(
                    color: pale,
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu catálogo de cuidados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Cada tarjeta es una opción independiente. '
                            'Crear o duplicar agrega otra opción; editar cambia solamente la tarjeta elegida.',
                            style: TextStyle(height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: createNew,
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.add_circle_outline), SizedBox(width: 10),
                          Text('Crear nuevo cuidado')]),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Explorar y filtrar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: speciesFilter,
                    decoration: const InputDecoration(
                      labelText: 'Especie',
                    ),
                    items: ['Todas', ...allPetSpecies]
                        .map(
                          (species) => DropdownMenuItem(
                            value: species,
                            child: Text(
                              species == 'Todas'
                                  ? 'Todas las especies'
                                  : '${emojiFor(species)}  $species',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => speciesFilter = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment<String>(
                          value: 'Todos',
                          label: Text('Todos'),
                        ),
                        ButtonSegment<String>(
                          value: 'Visibles',
                          label: Text('Visibles'),
                        ),
                        ButtonSegment<String>(
                          value: 'Ocultos',
                          label: Text('Ocultos'),
                        ),
                      ],
                      selected: {statusFilter},
                      onSelectionChanged: (selection) {
                        setState(() => statusFilter = selection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cuidados existentes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                      ),
                      Text(
                        '${shown.length}',
                        style: const TextStyle(
                          color: green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (shown.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Text(
                          'No hay cuidados con estos filtros. '
                          'Puedes cambiar el filtro o agregar uno nuevo.',
                        ),
                      ),
                    ),
                  ...shown.map((row) {
                    final active = row['active'] != false;
                    final description =
                        (row['description'] ?? '').toString().trim();

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? pale
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    careTypeIcon(row),
                                    color: active ? green : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        careTypeLabel(row),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? pale
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          active
                                              ? 'VISIBLE PARA USUARIOS'
                                              : 'OCULTO PARA USUARIOS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: active
                                                ? green
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                description,
                                style: const TextStyle(height: 1.35),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'Para: ${speciesText(row)}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const Divider(height: 26),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonal(
                                onPressed: () => edit(row),
                                child: const Text('Editar este cuidado'),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => duplicate(row),
                                    child: const Text('Duplicar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => changeActive(row),
                                    child: Text(
                                      active ? 'Ocultar' : 'Mostrar',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => remove(row),
                                child: const Text('Eliminar este cuidado'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class AdminCareTypeEditorPage extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Map<String, dynamic>? copyFrom;

  const AdminCareTypeEditorPage({
    super.key,
    this.existing,
    this.copyFrom,
  }) : assert(existing == null || copyFrom == null);

  @override
  State<AdminCareTypeEditorPage> createState() =>
      _AdminCareTypeEditorPageState();
}

class _AdminCareTypeEditorPageState
    extends State<AdminCareTypeEditorPage> {
  final label = TextEditingController();
  final description = TextEditingController();
  final selectedSpecies = <String>{};

  String icon = 'check';
  bool active = true;
  bool saving = false;
  bool allSpecies = false;

  bool get editing => widget.existing != null;
  bool get duplicating => widget.copyFrom != null;

  @override
  void initState() {
    super.initState();

    final source = widget.existing ?? widget.copyFrom;

    if (source != null) {
      final originalLabel = careTypeLabel(source);
      label.text = duplicating ? '$originalLabel - nuevo' : originalLabel;
      description.text =
          (source['description'] ?? '').toString();
      icon = (source['icon'] ?? 'check').toString();
      active = source['active'] != false;

      final raw = source['species'];
      if (raw is List) {
        selectedSpecies.addAll(
          raw.map((e) => e.toString()),
        );
      }
    }

    if (!careIconChoices.containsKey(icon)) {
      icon = 'check';
    }

    allSpecies =
        selectedSpecies.length == allPetSpecies.length;
  }

  @override
  void dispose() {
    label.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final title = label.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe el nombre del cuidado.'),
        ),
      );
      return;
    }

    if (!allSpecies && selectedSpecies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige al menos una especie.'),
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await CloudDb.instance.adminSaveCareType(
        careId: editing
            ? widget.existing!['id'].toString()
            : null,
        label: title,
        description: description.text.trim(),
        icon: icon,
        species: allSpecies
            ? allPetSpecies.toList()
            : allPetSpecies
                .where(selectedSpecies.contains)
                .toList(),
        active: active,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar. Revisa la conexión e inténtalo de nuevo.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeTitle = editing
        ? 'Editar cuidado'
        : duplicating
            ? 'Duplicar cuidado'
            : 'Nuevo cuidado';

    final explanation = editing
        ? 'Estás editando únicamente «${careTypeLabel(widget.existing!)}». '
            'Los demás cuidados no cambiarán.'
        : duplicating
            ? 'Vas a crear una opción NUEVA a partir de '
                '«${careTypeLabel(widget.copyFrom!)}». '
                'La original seguirá igual.'
            : 'Vas a crear una opción NUEVA. '
                'No se reemplazará ningún cuidado existente.';

    final previewTitle =
        label.text.trim().isEmpty
            ? 'Nombre del cuidado'
            : label.text.trim();

    final previewDescription =
        description.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          modeTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Card(
            color: pale,
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(backgroundColor: Colors.white,
                    child: Icon(editing ? Icons.edit_outlined
                        : duplicating ? Icons.copy
                            : Icons.add_circle_outline, color: green)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    explanation,
                    style: const TextStyle(
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '1. Nombre del cuidado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: label,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nombre que verá el usuario',
              hintText: 'Ej. Paseo sábado y domingo',
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: description,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText:
                  'Ej. Paseo tranquilo por el parque durante el fin de semana',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '2. ¿Para qué mascotas aparece?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 9),
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Todas las especies'),
            subtitle: const Text(
              'Desactívalo para elegir especies específicas.',
            ),
            value: allSpecies,
            onChanged: (value) {
              setState(() => allSpecies = value);
            },
          ),
          if (!allSpecies) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 5,
              children: allPetSpecies.map((species) {
                return FilterChip(
                  label: Text('${emojiFor(species)}  $species'),
                  selected:
                      selectedSpecies.contains(species),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedSpecies.add(species);
                      } else {
                        selectedSpecies.remove(species);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            '3. Visibilidad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 9),
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Mostrar a los usuarios'),
            subtitle: const Text(
              'Si lo ocultas, deja de aparecer como opción '
              'pero no borra el historial anterior.',
            ),
            value: active,
            onChanged: (value) {
              setState(() => active = value);
            },
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12),
            collapsedBackgroundColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Opcional: cambiar icono'),
            subtitle: const Text(
              'Puedes dejar el icono general si no quieres elegir uno.',
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: DropdownButtonFormField<String>(
                  initialValue: icon,
                  decoration:
                      const InputDecoration(labelText: 'Icono'),
                  items: careIconChoices.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(
                                careIcon(entry.key),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(entry.value),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => icon = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Vista previa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 9),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: pale,
                child: Icon(
                  careIcon(icon),
                  color: green,
                ),
              ),
              title: Text(
                previewTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: previewDescription.isEmpty
                  ? const Text('Así lo verá el usuario.')
                  : Text(previewDescription),
              trailing: Text(
                active ? 'Visible' : 'Oculto',
                style: TextStyle(
                  color: active ? green : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 55,
            child: FilledButton(
              onPressed: saving ? null : save,
              child: Text(
                saving
                    ? 'Guardando...'
                    : editing
                        ? 'GUARDAR CAMBIOS'
                        : 'CREAR COMO NUEVO CUIDADO',
              ),
            ),
          ),
          if (editing) ...[
            const SizedBox(height: 9),
            const Text(
              'Editar modifica solo este cuidado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ] else ...[
            const SizedBox(height: 9),
            const Text(
              'Se agregará como una opción independiente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminCareRecordEditorPage extends StatefulWidget {
  final String userId;
  final String petId;
  final List<Map<String, dynamic>> careTypes;
  final Map<String, dynamic>? existing;

  const AdminCareRecordEditorPage({
    super.key,
    required this.userId,
    required this.petId,
    required this.careTypes,
    this.existing,
  });

  @override
  State<AdminCareRecordEditorPage> createState() =>
      _AdminCareRecordEditorPageState();
}

class _AdminCareRecordEditorPageState
    extends State<AdminCareRecordEditorPage> {
  String? selectedId;
  final note = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final oldId = (widget.existing?['type'] ?? '').toString();
    final validOld = widget.careTypes.any(
      (row) => (row['id'] ?? '').toString() == oldId,
    );
    if (validOld) {
      selectedId = oldId;
    } else if (widget.careTypes.isNotEmpty) {
      selectedId = widget.careTypes.first['id'].toString();
    }
    note.text = (widget.existing?['note'] ?? '').toString();
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get selectedCare {
    if (selectedId == null) return null;
    return catalogCareById(widget.careTypes, selectedId!);
  }

  Future<void> save() async {
    final careType = selectedCare;
    if (careType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un tipo de cuidado.'),
        ),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await CloudDb.instance.adminAddCare(
          widget.userId,
          widget.petId,
          careType,
          note: note.text,
        );
      } else {
        await CloudDb.instance.adminUpdateCare(
          widget.userId,
          widget.petId,
          existing['id'].toString(),
          {
            'type': careType['id'].toString(),
            'label': careTypeLabel(careType),
            'note': note.text.trim(),
          },
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el cuidado.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existing == null
                ? 'Agregar cuidado'
                : 'Editar cuidado',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.careTypes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay tipos de cuidado activos para esta especie. '
                    'Primero agrégalos desde Gestionar cuidados.',
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cuidado',
                ),
                items: widget.careTypes
                    .map(
                      (row) => DropdownMenuItem(
                        value: row['id'].toString(),
                        child: Row(
                          children: [
                            Icon(careTypeIcon(row), size: 20),
                            const SizedBox(width: 10),
                            Text(careTypeLabel(row)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedId = value);
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota opcional',
                hintText: 'Ej. Dar después de la comida',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    saving || widget.careTypes.isEmpty ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  saving ? 'Guardando...' : 'Guardar cuidado',
                ),
              ),
            ),
          ],
        ),
      );
}

class AdminPetPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> pet;

  const AdminPetPage({
    super.key,
    required this.userId,
    required this.pet,
  });

  @override
  State<AdminPetPage> createState() => _AdminPetPageState();
}

class _AdminPetPageState extends State<AdminPetPage> {
  bool loading = true;
  List<Map<String, dynamic>> care = [];
  List<Map<String, dynamic>> careTypes = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await CloudDb.instance.adminCare(
      widget.userId,
      widget.pet['id'].toString(),
    );
    final types = await CloudDb.instance.careCatalogForSpecies(
      (widget.pet['species'] ?? '').toString(),
    );

    if (mounted) {
      setState(() {
        care = data;
        careTypes = types;
        loading = false;
      });
    }
  }

  Future<void> editCare([Map<String, dynamic>? row]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCareRecordEditorPage(
          userId: widget.userId,
          petId: widget.pet['id'].toString(),
          careTypes: careTypes,
          existing: row,
        ),
      ),
    );

    if (changed == true) {
      await load();
    }
  }

  Future<void> removeCare(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Eliminar este registro de '
          '«${careEntryLabel(row, careTypes)}»?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar registro'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await CloudDb.instance.adminDeleteCare(
        widget.userId,
        widget.pet['id'].toString(),
        row['id'].toString(),
      );
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final petName =
        (widget.pet['name'] ?? 'Mascota').toString();
    final species =
        (widget.pet['species'] ?? '').toString();
    final breed =
        (widget.pet['breed'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cuidados de $petName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            careTypes.isEmpty ? null : () => editCare(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar cuidado'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                Card(
                  color: pale,
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Row(
                      children: [
                        Text(
                          emojiFor(species),
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                petName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: ink,
                                ),
                              ),
                              Text(
                                breed.isEmpty
                                    ? species
                                    : '$species · $breed',
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Historial de cuidados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aquí puedes agregar, editar o eliminar '
                  'registros de esta mascota.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (careTypes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Esta especie no tiene tipos de cuidado visibles. '
                        'Créalo desde Administración → Tipos de cuidado.',
                      ),
                    ),
                  ),
                if (care.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Todavía no hay cuidados registrados.',
                        ),
                      ),
                    ),
                  ),
                ...care.map((row) {
                  final note =
                      (row['note'] ?? '').toString().trim();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: pale,
                                child: Icon(
                                  careEntryIcon(row, careTypes),
                                  color: green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      careEntryLabel(
                                        row,
                                        careTypes,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      (row['time'] ?? '').toString(),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(note),
                          ],
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => editCare(row),
                                  child: const Text('Editar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => removeCare(row),
                                  child: const Text('Eliminar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

