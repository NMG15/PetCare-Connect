import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

const _green = Color(0xFF257B54);
const _weekdayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _timeLabel(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String _friendlyTime(int hour, int minute) {
  final twelveHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$twelveHour:${minute.toString().padLeft(2, '0')} '
      '${hour < 12 ? 'a. m.' : 'p. m.'}';
}

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _careName(Map<String, dynamic> item) {
  final label = (item['label'] ?? '').toString().trim();
  return label.isNotEmpty ? label : (item['id'] ?? 'Cuidado').toString();
}

String _userUid() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Inicia sesión para continuar.');
  return user.uid;
}

DocumentReference<Map<String, dynamic>> _petDoc(String petId) =>
    FirebaseFirestore.instance.collection('users').doc(_userUid())
        .collection('pets').doc(petId);

CollectionReference<Map<String, dynamic>> _reminderDocs(String petId) =>
    _petDoc(petId).collection('reminders');

/// Avisos locales de Android. No hay servidor ni envío de notificaciones push.
/// Android puede retrasar avisos aproximados en modo ahorro de energía.
class PetCareAlerts {
  PetCareAlerts._();
  static final PetCareAlerts instance = PetCareAlerts._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'petcare_reminders_v1',
      'Recordatorios de mascotas',
      channelDescription: 'Horarios elegidos para los cuidados de tus mascotas',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    if (_ready) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    timezone_data.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_petcare'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  Future<void> showTest() async {
    await init();
    await _plugin.show(
      2147000000,
      'PetCare Connect 🐾',
      '¡Avisos activados! Recibirás tus horarios de cuidado en este celular.',
      _details,
    );
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  int _uniqueId(String userId, String petId, String reminderId, int weekday) {
    // FNV-1a, rango positivo y reservado para los recordatorios.
    var hash = 0x811C9DC5;
    for (final code in '$userId|$petId|$reminderId|$weekday'.codeUnits) {
      hash = (hash ^ code) * 0x01000193 & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute, int? weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    for (var attempts = 0; attempts < 9; attempts++) {
      if (candidate.isAfter(now) &&
          (weekday == null || candidate.weekday == weekday)) {
        return candidate;
      }
      // Constructor de fecha local: respeta cambios de horario de verano.
      candidate = tz.TZDateTime(
        tz.local, candidate.year, candidate.month, candidate.day + 1,
        hour, minute,
      );
    }
    throw StateError('No se pudo calcular el próximo aviso.');
  }

  Future<void> _scheduleOne({
    required String uid,
    required String petId,
    required String petName,
    required String reminderId,
    required String label,
    required String careId,
    required String note,
    required int hour,
    required int minute,
    required int? weekday,
  }) async {
    final when = _nextOccurrence(hour, minute, weekday);
    final id = _uniqueId(uid, petId, reminderId, weekday ?? 0);
    final foodCare = careId == 'feeding' ||
        label.toLowerCase().contains('alimentaci') ||
        label.toLowerCase().contains('comida');
    final message = foodCare
        ? 'Es hora de darle de comer a $petName. ¡Registra su comida en PetCare!'
        : 'Es hora de «$label» para $petName. Regístralo en PetCare.';
    final body = note.trim().isEmpty ? message : '$message Nota: ${note.trim()}';
    await _plugin.zonedSchedule(
      id,
      'Hora de cuidar a $petName 🐾',
      body,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: 'pet:$petId',
    );
  }

  /// Se ejecuta tras acceder a la cuenta y cuando se cambian sus horarios.
  /// Prepara las notificaciones para este dispositivo; una cuenta en otro
  /// celular debe iniciar sesión allí para programarlas también.
  Future<void> syncForUser(String userId) async {
    await init();
    final pets = await FirebaseFirestore.instance.collection('users')
        .doc(userId).collection('pets').get();
    final schedules = <({String petId, String petName, String reminderId,
        String label, String careId, String note,
        int hour, int minute, List<int> days})>[];

    for (final pet in pets.docs) {
      final data = pet.data();
      final hidden = (data['hiddenCareIds'] as List?)
              ?.map((e) => e.toString()).toSet() ??
          <String>{};
      final reminders = await pet.reference.collection('reminders').get();
      for (final reminder in reminders.docs) {
        final row = reminder.data();
        final careId = (row['careId'] ?? '').toString();
        if (row['enabled'] == false || hidden.contains(careId)) continue;
        final hour = (row['hour'] as num?)?.toInt() ?? -1;
        final minute = (row['minute'] as num?)?.toInt() ?? -1;
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) continue;
        final days = (row['days'] as List?)
                ?.whereType<num>().map((e) => e.toInt())
                .where((d) => d >= 1 && d <= 7).toList() ??
            <int>[];
        schedules.add((
          petId: pet.id,
          petName: (data['name'] ?? 'tu mascota').toString(),
          reminderId: reminder.id,
          label: (row['careLabel'] ?? 'un cuidado').toString(),
          careId: careId,
          note: (row['note'] ?? '').toString(),
          hour: hour,
          minute: minute,
          days: days,
        ));
      }
    }

    // Se cancela únicamente después de que las lecturas hayan terminado:
    // un fallo de red no borra por error los horarios vigentes del teléfono.
    await _plugin.cancelAll();
    for (final reminder in schedules) {
      final days = reminder.days;
      if (days.isEmpty) {
        await _scheduleOne(
          uid: userId, petId: reminder.petId,
          petName: reminder.petName, reminderId: reminder.reminderId,
          label: reminder.label, careId: reminder.careId,
          note: reminder.note, hour: reminder.hour,
          minute: reminder.minute, weekday: null,
        );
      } else {
        for (final weekday in days.toSet()) {
          await _scheduleOne(
            uid: userId, petId: reminder.petId,
            petName: reminder.petName, reminderId: reminder.reminderId,
            label: reminder.label, careId: reminder.careId,
            note: reminder.note, hour: reminder.hour,
            minute: reminder.minute, weekday: weekday,
          );
        }
      }
    }
  }
}

class PetCareVisibilityPage extends StatefulWidget {
  final String petId;
  final String petName;
  final String species;
  const PetCareVisibilityPage({
    super.key, required this.petId, required this.petName, required this.species,
  });

  @override
  State<PetCareVisibilityPage> createState() => _PetCareVisibilityPageState();
}

class _PetCareVisibilityPageState extends State<PetCareVisibilityPage> {
  List<Map<String, dynamic>> catalog = [];
  Set<String> hidden = {};
  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final pet = await _petDoc(widget.petId).get();
      final all = await FirebaseFirestore.instance.collection('careCatalog').get();
      final shown = all.docs.map((d) => {'id': d.id, ...d.data()})
          .where((care) {
            if (care['active'] == false) return false;
            final species = care['species'];
            return species is List && species.contains(widget.species);
          }).toList();
      if (mounted) {
        setState(() {
          catalog = shown;
          hidden = (pet.data()?['hiddenCareIds'] as List?)
                  ?.map((e) => e.toString()).toSet() ??
              <String>{};
          busy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> change(String careId, bool show) async {
    final updated = Set<String>.from(hidden);
    if (show) {
      updated.remove(careId);
    } else {
      updated.add(careId);
    }
    try {
      await _petDoc(widget.petId).set(
        {'hiddenCareIds': updated.toList()}, SetOptions(merge: true),
      );
      if (mounted) setState(() => hidden = updated);
      await PetCareAlerts.instance.syncForUser(_userUid());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo actualizar el cuidado. Comprueba Internet.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Mis cuidados visibles')),
        body: busy ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text('Elige los cuidados que necesita ${widget.petName}.',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  SizedBox(height: 8),
                  Text('Ocultar un cuidado no borra su historial. '
                      'Mientras esté oculto, tampoco se programarán sus avisos.'),
                  SizedBox(height: 14),
                  if (catalog.isEmpty)
                    Card(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay cuidados activos para esta especie. '
                          'El administrador puede agregarlos al catálogo.'),
                    )),
                  ...catalog.map((care) {
                    final id = care['id'].toString();
                    return Card(child: SwitchListTile(
                      title: Text(_careName(care)),
                      subtitle: Text(hidden.contains(id)
                          ? 'Oculto solo para esta mascota'
                          : 'Visible en sus cuidados diarios'),
                      value: !hidden.contains(id),
                      onChanged: (value) => change(id, value),
                    ));
                  }),
                ],
              ),
      );
}

class PetRemindersPage extends StatefulWidget {
  final String petId;
  final String petName;
  final String species;
  const PetRemindersPage({
    super.key, required this.petId, required this.petName, required this.species,
  });
  @override
  State<PetRemindersPage> createState() => _PetRemindersPageState();
}

class _PetRemindersPageState extends State<PetRemindersPage> {
  List<Map<String, dynamic>> reminders = [];
  List<Map<String, dynamic>> careTypes = [];
  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final pet = await _petDoc(widget.petId).get();
      final hidden = (pet.data()?['hiddenCareIds'] as List?)
              ?.map((e) => e.toString()).toSet() ??
          <String>{};
      final types = await FirebaseFirestore.instance.collection('careCatalog').get();
      final remindersSnap = await _reminderDocs(widget.petId).get();
      if (mounted) {
        setState(() {
          reminders = remindersSnap.docs
              .map((d) => {'id': d.id, ...d.data()}).toList()
            ..sort((a, b) {
              final first = ((a['hour'] as num?)?.toInt() ?? 0) * 60 +
                  ((a['minute'] as num?)?.toInt() ?? 0);
              final second = ((b['hour'] as num?)?.toInt() ?? 0) * 60 +
                  ((b['minute'] as num?)?.toInt() ?? 0);
              return first.compareTo(second);
            });
          careTypes = types.docs.map((d) => {'id': d.id, ...d.data()})
            .where((e) => e['active'] != false &&
                (e['species'] as List?)?.contains(widget.species) == true &&
                !hidden.contains(e['id'])).toList();
          busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudieron cargar los horarios. Revisa Internet.'),
        ));
      }
    }
  }

  Future<void> edit([Map<String, dynamic>? existing]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => ReminderEditorPage(
        petId: widget.petId,
        petName: widget.petName,
        careTypes: careTypes,
        existing: existing,
      ),
    ));
    if (changed == true) await load();
  }

  Future<void> delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar horario'),
        content: Text('¿Quitar el aviso de «${row['careLabel']}» a las '
            '${_timeLabel((row['hour'] as num).toInt(), (row['minute'] as num).toInt())}? '
            'Los cuidados ya registrados seguirán en el historial.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar horario')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _reminderDocs(widget.petId).doc(row['id'].toString()).delete();
      await PetCareAlerts.instance.syncForUser(_userUid());
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo eliminar el horario.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Horarios de ${widget.petName}')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: busy || careTypes.isEmpty ? null : () => edit(),
      icon: Icon(Icons.add_alarm),
      label: Text('Nuevo horario'),
    ),
    body: busy ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 23, backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(Icons.notifications_active_outlined, color: Theme.of(context).colorScheme.primary),
                    ),
                    SizedBox(width: 13),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sus cuidados, a tiempo',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                        SizedBox(height: 5),
                        Text('Elige qué cuidado recordar, a qué hora y en qué días. '
                          '${reminders.length} ${reminders.length == 1 ? 'horario activo' : 'horarios activos'}.',
                          style: TextStyle(height: 1.35)),
                      ],
                    )),
                  ]),
                ),
              ),
              SizedBox(height: 20),
              Row(children: [
                Expanded(child: Text('Mis recordatorios',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface))),
                Text('${reminders.length}',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
              ]),
              SizedBox(height: 10),
              if (reminders.isEmpty)
                Card(child: Padding(padding: EdgeInsets.all(22),
                  child: Column(children: [
                    Icon(Icons.event_available, color: Theme.of(context).colorScheme.primary, size: 36),
                    SizedBox(height: 10),
                    Text('Aún no hay horarios para esta mascota.',
                      textAlign: TextAlign.center),
                    SizedBox(height: 5),
                    Text('Pulsa «Nuevo horario» para programar su comida u otro cuidado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ]),
                )),
              ...reminders.map((row) {
                final hour = (row['hour'] as num?)?.toInt() ?? 0;
                final minute = (row['minute'] as num?)?.toInt() ?? 0;
                final days = (row['days'] as List?)?.whereType<num>()
                    .map((value) => value.toInt())
                    .where((value) => value >= 1 && value <= 7).toList() ?? <int>[];
                final daysLabel = days.isEmpty ? 'Todos los días'
                    : days.map((day) => _weekdayNames[day - 1]).join(' · ');
                return Card(
                  margin: const EdgeInsets.only(bottom: 11),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 11),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14)),
                            child: Text(_friendlyTime(hour, minute),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((row['careLabel'] ?? 'Cuidado').toString(),
                                style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text(daysLabel, style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          )),
                        ]),
                        if ((row['note'] ?? '').toString().trim().isNotEmpty) ...[
                          SizedBox(height: 10),
                          Text(row['note'].toString(),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                        Divider(height: 22),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => edit(row),
                            icon: Icon(Icons.edit_outlined, size: 18),
                            label: Text('Editar'),
                          )),
                          SizedBox(width: 8),
                          Expanded(child: TextButton.icon(
                            onPressed: () => delete(row),
                            icon: Icon(Icons.delete_outline, size: 18),
                            label: Text('Eliminar'),
                          )),
                        ]),
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

class ReminderEditorPage extends StatefulWidget {
  final String petId;
  final String petName;
  final List<Map<String, dynamic>> careTypes;
  final Map<String, dynamic>? existing;
  const ReminderEditorPage({
    super.key, required this.petId, required this.petName,
    required this.careTypes, this.existing,
  });
  @override
  State<ReminderEditorPage> createState() => _ReminderEditorPageState();
}

class _ReminderEditorPageState extends State<ReminderEditorPage> {
  String? careId;
  TimeOfDay time = const TimeOfDay(hour: 17, minute: 0);
  final weekdays = <int>{};
  final note = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    final preferred = (old?['careId'] ?? '').toString();
    if (widget.careTypes.any((item) => item['id'] == preferred)) {
      careId = preferred;
    } else if (widget.careTypes.isNotEmpty) {
      careId = widget.careTypes.first['id'].toString();
    }
    final hour = (old?['hour'] as num?)?.toInt() ?? 17;
    final minute = (old?['minute'] as num?)?.toInt() ?? 0;
    if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
      time = TimeOfDay(hour: hour, minute: minute);
    }
    final savedDays = (old?['days'] as List?)
        ?.whereType<num>().map((e) => e.toInt())
        .where((day) => day >= 1 && day <= 7).toSet() ?? <int>{};
    // Los horarios antiguos guardaban [] para indicar repetición diaria.
    if (old != null && savedDays.isEmpty) {
      weekdays.addAll(List<int>.generate(7, (index) => index + 1));
    } else {
      weekdays.addAll(savedDays);
    }
    note.text = (old?['note'] ?? '').toString();
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (careId == null || saving) return;
    if (weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona al menos un día o pulsa Todos los días.'),
      ));
      return;
    }
    setState(() => saving = true);
    final chosen = widget.careTypes.firstWhere((row) => row['id'] == careId);
    try {
      final permitted = await PetCareAlerts.instance.requestPermission();
      if (!permitted) {
        if (mounted) {
          setState(() => saving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Activa las notificaciones para guardar un horario con aviso.'),
          ));
        }
        return;
      }
      final data = {
        'careId': careId,
        'careLabel': _careName(chosen),
        'hour': time.hour,
        'minute': time.minute,
        'days': weekdays.toList()..sort(),
        'note': note.text.trim(),
        'enabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.existing == null) {
        await _reminderDocs(widget.petId).add({
          ...data, 'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _reminderDocs(widget.petId)
            .doc(widget.existing!['id'].toString())
            .set(data, SetOptions(merge: true));
      }
      await PetCareAlerts.instance.syncForUser(_userUid());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('El horario puede haberse guardado, pero no se '
              'confirmó su notificación. Reintenta desde Horarios. $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.existing == null
        ? 'Crear horario' : 'Editar horario')),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: [
        Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(children: [
            Icon(Icons.pets, color: Theme.of(context).colorScheme.primary, size: 28),
            SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recordatorio · ${widget.petName}',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 3),
                Text('Elige un cuidado, su hora y los días de repetición.'),
              ],
            )),
          ]),
        )),
        SizedBox(height: 22),
        Text('1  ·  Elige el cuidado', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 9),
        Text('Cuidado', style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: careId,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.check_circle_outline),
          ),
          items: widget.careTypes.map((row) => DropdownMenuItem(
            value: row['id'].toString(), child: Text(_careName(row)),
          )).toList(),
          onChanged: (value) => setState(() => careId = value),
        ),
        SizedBox(height: 23),
        Text('2  ·  Elige la hora', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 9),
        Card(child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            final selected = await showTimePicker(
              context: context, initialTime: time,
            );
            if (selected != null && mounted) setState(() => time = selected);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary)),
              SizedBox(width: 13),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hora del aviso',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  SizedBox(height: 3),
                  Text(_friendlyTime(time.hour, time.minute),
                    style: TextStyle(fontSize: 25,
                        fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                ],
              )),
              Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
            ]),
          ),
        )),
        SizedBox(height: 23),
        Text('3  ·  Días de repetición', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 5),
        Row(children: [
          Expanded(child: Text(
            weekdays.isEmpty ? 'Sin días seleccionados'
              : weekdays.length == 7 ? 'Todos los días'
              : '${weekdays.length} días seleccionados',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )),
          ActionChip(
            avatar: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Todos los días'),
            tooltip: weekdays.length == 7
                ? 'Deseleccionar todos los días' : 'Seleccionar los siete días',
            onPressed: () => setState(() {
              if (weekdays.length == 7) {
                weekdays.clear();
              } else {
                weekdays.addAll(List<int>.generate(7, (i) => i + 1));
              }
            }),
          ),
        ]),
        SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 5,
          children: List.generate(7, (index) {
            final day = index + 1;
            return FilterChip(
              label: Text(_weekdayNames[index]),
              selected: weekdays.contains(day),
              onSelected: (selected) => setState(() {
                if (selected) { weekdays.add(day); }
                else { weekdays.remove(day); }
              }),
            );
          }),
        ),
        SizedBox(height: 23),
        Text('Nota opcional', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 9),
        TextField(
          controller: note,
          minLines: 2,
          maxLines: 3,
          textAlignVertical: TextAlignVertical.center,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.edit_note_outlined),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: 'Ej. 1 taza de croquetas',
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
    bottomNavigationBar: _petCareRemindersFooter(
      context,
      FilledButton.icon(
        onPressed: saving ? null : save,
        icon: const Icon(Icons.check),
        label: Text(saving ? 'Guardando...' : 'Guardar horario'),
      ),
    ),
  );
}

class PetHistoryPage extends StatefulWidget {
  final String petId;
  final String petName;
  const PetHistoryPage({
    super.key, required this.petId, required this.petName,
  });
  @override
  State<PetHistoryPage> createState() => _PetHistoryPageState();
}

class _PetHistoryPageState extends State<PetHistoryPage> {
  List<Map<String, dynamic>> entries = [];
  bool busy = true;
  int selectedPeriod = 0; // 0 semana, 1 mes, 2 año, 3 todos los años
  DateTime anchor = DateTime.now();
  Map<String, String> namesByType = {};
  DateTime? selectedCalendarDate;
  Map<String, Color>? _cachedCareColors;

  // Se conserva el mismo color para cada tipo a través de todas las vistas.
  static const _baseColors = <String, Color>{
    'feeding': Color(0xFFE29B29), // Alimentación: ámbar
    'water': Color(0xFF287CC7), // Agua: azul
    'walk': Color(0xFFDD7840),
    'hygiene': Color(0xFF1E9E97),
    'habitat': Color(0xFF8361C7),
    'play': Color(0xFFBD608F),
    'aquarium': Color(0xFF368DB4),
    'medicine': Color(0xFFCA5966),
    'vet': Color(0xFF697DD1),
  };
  static const _extraColors = <Color>[
    Color(0xFF4A8B60), Color(0xFF9C6C37), Color(0xFF9866B4),
    Color(0xFF1D93AD), Color(0xFFCF6D5B), Color(0xFF6B7E36),
    Color(0xFFB85999), Color(0xFF4384AE), Color(0xFF947348),
    Color(0xFF508B83), Color(0xFFB86B40), Color(0xFF7B69A5),
  ];

  String _typeKey(Map<String, dynamic> entry) {
    final type = (entry['type'] ?? '').toString().trim();
    if (type.isNotEmpty) return type;
    return (entry['label'] ?? 'Cuidado').toString().trim();
  }

  String _typeName(Map<String, dynamic> entry) {
    final type = _typeKey(entry);
    // Nombre normalizado de la opción predeterminada, incluidos registros antiguos.
    if (type == 'habitat') return 'Limpieza del hábitat';
    final saved = (entry['label'] ?? '').toString().trim();
    var name = saved.isNotEmpty ? saved : (namesByType[type] ?? type);
    // Solo se corrige el rótulo visible; no se modifica ningún documento.
    name = name.replaceAll(RegExp(r'\bhábitat\s+hábitat\b',
        caseSensitive: false), 'hábitat');
    if (name.toLowerCase() == 'habitat' || name.toLowerCase() == 'hábitat') {
      return 'Limpieza del hábitat';
    }
    return name;
  }

  Map<String, Color> get _colorsByType {
    // Los cuidados nuevos del administrador reciben también un color propio.
    return _cachedCareColors ??= _buildCareColors();
  }

  Map<String, Color> _buildCareColors() {
    final custom = entries.map(_typeKey).toSet().where(
        (key) => !_baseColors.containsKey(key)).toList()..sort();
    return {
      ..._baseColors,
      for (var i = 0; i < custom.length; i++)
        custom[i]: _extraColors[i % _extraColors.length],
    };
  }

  Color _colorFor(String key) => _colorsByType[key] ?? _green;

  Map<String, int> _countsByType(List<Map<String, dynamic>> rows) {
    final result = <String, int>{};
    for (final entry in rows) {
      final type = _typeKey(entry);
      result[type] = (result[type] ?? 0) + 1;
    }
    return result;
  }

  String _nameForType(String key) {
    for (final row in entries) {
      if (_typeKey(row) == key) return _typeName(row);
    }
    return namesByType[key] ?? key;
  }

  String _times(int count) => count == 1 ? '1 vez' : '$count veces';
  String _careCount(int count) =>
      count == 1 ? '1 cuidado' : '$count cuidados';

  Widget _dot(Color color, {double size = 7}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  /// Cada punto representa un tipo de cuidado distinto registrado ese día.
  /// En el calendario solo mostramos puntos de color (sin '+2', '+3', etc.)
  /// para mantener el estilo limpio y evitar que se amontonen en celdas pequeñas.
  Widget _typeDots(List<Map<String, dynamic>> rows,
      {int maxDots = 5, double diameter = 6.5}) {
    final types = _countsByType(rows).keys.toList()..sort();
    final visibleTypes = types.take(maxDots).toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: visibleTypes.map((key) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.4),
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: _colorFor(key),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 1.5,
                  offset: Offset(0, 0.5),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _typeChip(String key, int count) {
    final color = _colorFor(key);
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 85),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.23)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _dot(color, size: 8), SizedBox(width: 7),
        Flexible(child: Text('${_nameForType(key)} · ${_times(count)}',
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  void _openDayDetails(DateTime day, List<Map<String, dynamic>> rows) {
    final grouped = _countsByType(rows).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
            child: ListView(shrinkWrap: true, children: [
              Text('${day.day} de ${_months[day.month - 1]} de ${day.year}',
                style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 5),
              Text('${_careCount(rows.length)} registrados ese día',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              SizedBox(height: 17),
              if (rows.isEmpty)
                Text('No hay cuidados registrados en esta fecha.'),
              ...grouped.map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(children: [
                  _dot(_colorFor(group.key), size: 11),
                  SizedBox(width: 10),
                  Expanded(child: Text(_nameForType(group.key),
                    style: TextStyle(fontWeight: FontWeight.w600))),
                  Text(_times(group.value),
                    style: TextStyle(fontWeight: FontWeight.w800)),
                ]))),
              if (rows.isNotEmpty) ...[
                Divider(height: 27),
                Text('Registros del día', style: TextStyle(
                  fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                ...rows.map((row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _dot(_colorFor(_typeKey(row)), size: 10),
                  title: Text(_typeName(row)),
                  subtitle: Text((row['time'] ?? '').toString().trim().isEmpty
                    ? 'Sin hora registrada' : row['time'].toString()),
                )),
              ],
            ]),
          ),
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await _petDoc(widget.petId).collection('care')
          .orderBy('createdAt', descending: true).get();
      final catalog = await FirebaseFirestore.instance
          .collection('careCatalog').get();
      if (mounted) {
        setState(() {
          entries = data.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _cachedCareColors = null;
          namesByType = {for (final doc in catalog.docs)
            doc.id: (doc.data()['label'] ?? doc.id).toString()};
          busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo cargar el historial. Comprueba Internet.'),
        ));
      }
    }
  }

  DateTime? _entryDate(Map<String, dynamic> row) {
    final stamp = row['createdAt'];
    if (stamp is Timestamp) return stamp.toDate();
    return DateTime.tryParse((stamp ?? '').toString());
  }

  DateTime get periodStart {
    if (selectedPeriod == 0) {
      final date = DateTime(anchor.year, anchor.month, anchor.day);
      return date.subtract(Duration(days: date.weekday - 1));
    }
    if (selectedPeriod == 1) return DateTime(anchor.year, anchor.month);
    if (selectedPeriod == 2) return DateTime(anchor.year);
    return DateTime(1970);
  }

  DateTime get periodEnd {
    if (selectedPeriod == 0) return periodStart.add(const Duration(days: 7));
    if (selectedPeriod == 1) return DateTime(anchor.year, anchor.month + 1);
    if (selectedPeriod == 2) return DateTime(anchor.year + 1);
    return DateTime(3000);
  }

  String get periodTitle {
    if (selectedPeriod == 0) {
      return '${_dateLabel(periodStart)} – '
          '${_dateLabel(periodEnd.subtract(const Duration(days: 1)))}';
    }
    if (selectedPeriod == 1) return '${_months[anchor.month - 1]} de ${anchor.year}';
    if (selectedPeriod == 2) return '${anchor.year}';
    return 'Todos los años';
  }

  void shift(int amount) {
    setState(() {
      if (selectedPeriod == 0) {
        anchor = anchor.add(Duration(days: 7 * amount));
      } else if (selectedPeriod == 1) {
        anchor = DateTime(anchor.year, anchor.month + amount);
      } else if (selectedPeriod == 2) {
        anchor = DateTime(anchor.year + amount, anchor.month, anchor.day);
      }
    });
  }

  /// Un punto equivale a un TIPO de cuidado, no a un registro.
  /// El recuento por actividad de la fecha seleccionada está bajo el calendario.
  Widget monthCalendar(List<Map<String, dynamic>> inPeriod) {
    final firstDay = DateTime(anchor.year, anchor.month);
    final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
    final offset = firstDay.weekday - 1;
    final rowsByDay = <int, List<Map<String, dynamic>>>{};
    for (final entry in inPeriod) {
      final date = _entryDate(entry);
      if (date != null) {
        rowsByDay.putIfAbsent(date.day, () => []).add(entry);
      }
    }
    final today = DateTime.now();
    final selected = selectedCalendarDate;
    final selectedDay = selected != null && selected.year == anchor.year &&
            selected.month == anchor.month
        ? selected.day
        : today.year == anchor.year && today.month == anchor.month &&
                rowsByDay.containsKey(today.day)
            ? today.day
            : rowsByDay.keys.isEmpty
                ? today.year == anchor.year && today.month == anchor.month
                    ? today.day : 1
                : rowsByDay.keys.reduce((a, b) => a > b ? a : b);
    final dayRecords = rowsByDay[selectedDay] ?? <Map<String, dynamic>>[];
    final selectedCounts = _countsByType(dayRecords).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final calendarDate = DateTime(anchor.year, anchor.month, selectedDay);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.primary, size: 23),
            SizedBox(width: 8),
            Expanded(child: Text('Calendario de cuidados', style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800))),
          ]),
          SizedBox(height: 6),
          Text('Selecciona una fecha para ver sus cuidados. '
              'Los puntos indican diferentes tipos de actividad.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, height: 1.35)),
          SizedBox(height: 14),
          Row(children: _weekdayNames.map((day) => Expanded(
            child: Center(child: Text(day, style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11,
              fontWeight: FontWeight.w700))),
          )).toList()),
          SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.69,
              mainAxisSpacing: 4,
              crossAxisSpacing: 3,
            ),
            itemBuilder: (ctx, index) {
              if (index < offset) return const SizedBox.shrink();
              final day = index - offset + 1;
              final records = rowsByDay[day] ?? <Map<String, dynamic>>[];
              final isToday = today.year == anchor.year &&
                  today.month == anchor.month && today.day == day;
              final active = selectedDay == day;
              return Semantics(
                button: true,
                label: '$day de ${_months[anchor.month - 1]}. '
                    '${_careCount(records.length)}. Seleccionar para ver tipos.',
                child: InkWell(
                  onTap: () => setState(() => selectedCalendarDate =
                      DateTime(anchor.year, anchor.month, day)),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: active ? Theme.of(context).colorScheme.primary
                          : (records.isEmpty
                            ? Theme.of(context).colorScheme.surfaceContainerLow
                            : Theme.of(context).colorScheme.primaryContainer),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? _green : (isToday
                          ? const Color(0xFF9ABDAA) : Colors.transparent),
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day', style: TextStyle(fontSize: 13,
                          fontWeight: active || isToday
                              ? FontWeight.w800 : FontWeight.w500,
                          color: active
                              ? Theme.of(context).colorScheme.onPrimary
                              : records.isNotEmpty
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface)),
                        SizedBox(height: 4),
                        SizedBox(height: 7,
                          child: records.isEmpty
                              ? const SizedBox.shrink()
                              : _typeDots(records, maxDots: 5, diameter: 6.5)),
                        SizedBox(height: 3),
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: records.isEmpty
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            records.isEmpty ? '' : '${records.length}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : records.isNotEmpty
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$selectedDay de ${_months[anchor.month - 1]} · '
                    '${_careCount(dayRecords.length)}',
                  style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 8),
                if (dayRecords.isEmpty)
                  Text('No registraste cuidados este día.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                if (selectedCounts.isNotEmpty) Wrap(
                  spacing: 6, runSpacing: 6,
                  children: selectedCounts.map((group) =>
                    _typeChip(group.key, group.value)).toList(),
                ),
                if (dayRecords.isNotEmpty) ...[
                  SizedBox(height: 9),
                  TextButton.icon(
                    onPressed: () => _openDayDetails(calendarDate, dayRecords),
                    icon: Icon(Icons.list_alt_outlined, size: 18),
                    label: Text('Ver horarios y registros del día'),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> deleteEntry(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar registro'),
        content: Text('¿Eliminar este cuidado de tu historial? '
            'Esto no modifica el horario programado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await _petDoc(widget.petId).collection('care')
        .doc(row['id'].toString()).delete();
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final inPeriod = entries.where((row) {
      final date = _entryDate(row);
      return date != null && !date.isBefore(periodStart)
          && date.isBefore(periodEnd);
    }).toList();
    final perType = _countsByType(inPeriod);
    final days = <String>{};
    for (final row in inPeriod) {
      final dt = _entryDate(row)!;
      days.add('${dt.year}-${dt.month}-${dt.day}');
    }
    final groupedTypes = perType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final row in inPeriod) {
      final date = _dateLabel(_entryDate(row)!);
      byDay.putIfAbsent(date, () => []).add(row);
    }
    return Scaffold(
      appBar: AppBar(title: Text('Historial de ${widget.petName}')),
      body: busy ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: load,
            child: ListView(padding: EdgeInsets.fromLTRB(
              18, 12, 18, MediaQuery.viewPaddingOf(context).bottom + 104),
              children: [
                Card(color: Theme.of(context).colorScheme.primaryContainer, margin: EdgeInsets.zero,
                  child: Padding(padding: const EdgeInsets.all(17),
                    child: Row(children: [
                      CircleAvatar(radius: 22,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: Icon(Icons.insights_outlined, color: Theme.of(context).colorScheme.primary)),
                      SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('El día a día de ${widget.petName}',
                            style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                          SizedBox(height: 4),
                          Text('Consulta cada actividad, su frecuencia '
                            'y cuándo la registraste.',
                            style: TextStyle(fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      )),
                    ]),
                  ),
                ),
                SizedBox(height: 10),
                SingleChildScrollView(scrollDirection: Axis.horizontal,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Semana')),
                      ButtonSegment(value: 1, label: Text('Mes')),
                      ButtonSegment(value: 2, label: Text('Año')),
                      ButtonSegment(value: 3, label: Text('Todos')),
                    ],
                    selected: {selectedPeriod},
                    onSelectionChanged: (choice) => setState(() {
                      selectedPeriod = choice.first;
                      anchor = DateTime.now();
                    }),
                  ),
                ),
                SizedBox(height: 12),
                Row(children: [
                  if (selectedPeriod != 3)
                    IconButton(onPressed: () => shift(-1),
                        icon: Icon(Icons.chevron_left),
                        tooltip: 'Periodo anterior'),
                  Expanded(child: Text(periodTitle, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold))),
                  if (selectedPeriod != 3)
                    IconButton(onPressed: () => shift(1),
                        icon: Icon(Icons.chevron_right),
                        tooltip: 'Periodo siguiente'),
                ]),
                SizedBox(height: 12),
                Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.verified_outlined, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(child: Text(_careCount(inPeriod.length),
                          style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface))),
                      ]),
                      SizedBox(height: 5),
                      Text('En ${days.length} días diferentes.'),
                      if (selectedPeriod == 0) ...[
                        SizedBox(height: 13),
                        ...List.generate(7, (index) {
                          final day = periodStart.add(Duration(days: index));
                          final todayEntries = inPeriod.where((row) {
                            final stamp = _entryDate(row)!;
                            return stamp.year == day.year &&
                                stamp.month == day.month && stamp.day == day.day;
                          }).toList();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(children: [
                              SizedBox(width: 46,
                                child: Text(_weekdayNames[index],
                                  style: TextStyle(fontWeight: FontWeight.w700))),
                              Expanded(child: Align(
                                alignment: Alignment.centerLeft,
                                child: _typeDots(todayEntries, maxDots: 6,
                                  diameter: 9))),
                              Text(_careCount(todayEntries.length),
                                style: TextStyle(fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
                            ]),
                          );
                        }),
                      ],
                    ],
                  ),
                )),
                if (selectedPeriod == 1) ...[
                  SizedBox(height: 12),
                  monthCalendar(inPeriod),
                ],
                SizedBox(height: 17),
                Text('Cuidados por actividad',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 4),
                Text('Cada actividad tiene un color; el número indica '
                    'cuántas veces quedó registrada en el periodo.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                SizedBox(height: 8),
                if (groupedTypes.isEmpty)
                  Card(child: Padding(padding: EdgeInsets.all(20),
                      child: Text('No hay registros en este periodo.'))),
                ...groupedTypes.map((group) => Card(
                  margin: const EdgeInsets.only(bottom: 7),
                  child: ListTile(
                    leading: CircleAvatar(radius: 17,
                      backgroundColor: _colorFor(group.key).withValues(alpha: 0.13),
                      child: _dot(_colorFor(group.key), size: 12)),
                    title: Text(_nameForType(group.key),
                      style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(_times(group.value),
                      style: TextStyle(fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
                  ),
                )),
                SizedBox(height: 18),
                Text('Registro por día',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 7),
                ...byDay.entries.map((group) => Card(
                  child: Padding(padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.event_note_outlined,
                              size: 18, color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 7),
                          Expanded(child: Text(group.key,
                            style: TextStyle(fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface))),
                          Text(_careCount(group.value.length),
                            style: TextStyle(fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]),
                        ...group.value.map((row) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: _dot(_colorFor(_typeKey(row)), size: 10),
                            title: Text(_typeName(row)),
                            subtitle: Text((row['time'] ?? '').toString()),
                            trailing: IconButton(
                              tooltip: 'Eliminar registro',
                              icon: Icon(Icons.delete_outline),
                              onPressed: () => deleteEntry(row),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                )),
                SizedBox(height: 14),
                Text('Aquí aparecen los cuidados que registraste.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
    );
  }
}


/// Mantiene las acciones sobre la barra de gestos / botones Android.
Widget _petCareRemindersFooter(BuildContext context, Widget button) {
  final bottomInset = MediaQuery.of(context).viewPadding.bottom;
  final bottomSpace = bottomInset < 48 ? 72.0 : bottomInset + 16.0;
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, bottomSpace),
      child: SizedBox(height: 54, width: double.infinity, child: button),
    ),
  );
}
