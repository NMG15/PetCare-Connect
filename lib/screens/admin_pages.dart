// PetCare Connect: módulo del mismo paquete Dart; comparte los componentes internos.
part of '../main.dart';

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
          SnackBar(
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
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: adaptiveMuted(context),
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
                    color: adaptivePale(context),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: adaptiveInk(context),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: adaptiveMuted(context),
                height: 1.35,
              ),
            ),
            SizedBox(height: 16),
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
        title: Text('Administración', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Actualizar estadísticas',
            icon: Icon(Icons.refresh_outlined),
            onPressed: () { setState(() => loading = true); load(); },
          ),
          IconButton(
            tooltip: 'Apariencia',
            icon: Icon(Icons.palette_outlined),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AppearanceSettingsPage())),
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ink, green],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
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
                  SizedBox(height: 14),
                  Row(
                    children: [
                      summaryBox('${users.length}', 'Usuarios'),
                      SizedBox(width: 8),
                      summaryBox('$petsCount', 'Mascotas'),
                      SizedBox(width: 8),
                      summaryBox('$careTypesCount', 'Cuidados'),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    '¿Qué quieres administrar?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: adaptiveInk(context),
                    ),
                  ),
                  SizedBox(height: 12),
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
                  SizedBox(height: 10),
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

class AdminUsersListPage extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  const AdminUsersListPage({super.key, required this.users});

  @override
  State<AdminUsersListPage> createState() => _AdminUsersListPageState();
}

class _AdminUsersListPageState extends State<AdminUsersListPage> {
  final search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = query.trim().toLowerCase();
    final filtered = widget.users.where((user) {
      if (term.isEmpty) return true;
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return name.contains(term) || email.contains(term);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Usuarios y mascotas')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: search,
            onChanged: (value) => setState(() => query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar usuarios',
              hintText: 'Nombre o correo electrónico',
              prefixIcon: Icon(Icons.search_outlined),
              suffixIcon: query.isEmpty ? null : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () => setState(() { search.clear(); query = ''; }),
                icon: Icon(Icons.clear),
              ),
            ),
          ),
          SizedBox(height: 14),
          Text('${filtered.length} de ${widget.users.length} usuarios',
            style: TextStyle(color: adaptiveMuted(context))),
          SizedBox(height: 12),
          if (filtered.isEmpty)
            Card(child: Padding(
              padding: EdgeInsets.all(25),
              child: Center(child: Text('No hay usuarios que coincidan con la búsqueda.')),
            )),
          for (final user in filtered)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: adaptivePale(context),
                  child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text((user['name'] ?? '').toString().trim().isEmpty
                    ? 'Usuario' : user['name'].toString()),
                subtitle: Text((user['email'] ?? '').toString()),
                trailing: Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AdminUserPage(user: user))),
              ),
            ),
        ],
      ),
    );
  }
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
        title: Text('Eliminar mascota'),
        content: Text(
          '¿Eliminar ${pet['name']}, sus cuidados y recordatorios? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Eliminar mascota'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await CloudDb.instance.adminDeletePet(
          userId,
          pet['id'].toString(),
        );
      } catch (e) {
        debugPrint('ADMIN_PET_DELETE_ERROR: ${e.runtimeType}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo completar la eliminación. Algunos registros podrían haberse eliminado. Actualiza la lista antes de reintentar.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mascota eliminada correctamente.'),
        ),
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editPet(),
        icon: Icon(Icons.add),
        label: Text('Agregar mascota'),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datos del usuario',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: adaptiveInk(context),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          userName.isEmpty ? 'Sin nombre registrado' : userName,
                        ),
                        SizedBox(height: 3),
                        Text(
                          email,
                          style: TextStyle(color: adaptiveMuted(context)),
                        ),
                        SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: editUser,
                            child: Text('Editar datos del usuario'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mascotas de este usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: adaptiveInk(context),
                        ),
                      ),
                    ),
                    Text(
                      '${pets.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (pets.isEmpty)
                  Card(
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
                                backgroundColor: adaptivePale(context),
                                child: Text(emojiFor(species)),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      petName,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      breed.isEmpty
                                          ? species
                                          : '$species · $breed',
                                      style: TextStyle(
                                        color: adaptiveMuted(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: () => openPet(pet),
                              child: Text('Ver y administrar cuidados'),
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => editPet(pet),
                                  child: Text('Editar mascota'),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => removePet(pet),
                                  child: Text('Eliminar'),
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
        SnackBar(content: Text('Escribe un nombre.')),
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
          SnackBar(
            content: Text('No se pudo actualizar el usuario.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
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
              decoration: InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              initialValue: (widget.user['email'] ?? '').toString(),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
                helperText:
                    'El correo de acceso no se modifica desde el panel.',
              ),
            ),
            SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: saving ? null : save,
                icon: Icon(Icons.save_outlined),
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
        SnackBar(
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
          SnackBar(
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Text(
            'Datos de la mascota',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: adaptiveInk(context),
            ),
          ),
          SizedBox(height: 14),
          Text('Nombre de la mascota', style: TextStyle(color: adaptiveMuted(context))),
          const SizedBox(height: 7),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Nombre de la mascota',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          SizedBox(height: 12),
          Text('Especie', style: TextStyle(color: adaptiveMuted(context))),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: species,
            decoration: InputDecoration(
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
          SizedBox(height: 12),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
            title: Text('Raza / categoría'),
            subtitle: Text(
              breed,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: selectBreed,
          ),
          SizedBox(height: 12),
          Text('Sexo', style: TextStyle(color: adaptiveMuted(context))),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: sex,
            decoration: const InputDecoration(),
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
          SizedBox(height: 12),
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
              SizedBox(width: 10),
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
                  decoration: InputDecoration(
                    labelText: 'Peso',
                    hintText: 'Ej. 15',
                    suffixText: 'kg',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Card(child: ListTile(
            leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text('Colores'),
            subtitle: Text(color.text.trim().isEmpty
                ? 'Selecciona uno o varios colores'
                : color.text.trim()),
            trailing: Icon(Icons.expand_more),
            onTap: () async {
              final value = await choosePetColors(context, color.text);
              if (value != null && mounted) setState(() => color.text = value);
            },
          )),
          SizedBox(height: 12),
          Text(coatLabel, style: TextStyle(color: adaptiveMuted(context))),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            key: ValueKey('admin-pelaje-$species'),
            isExpanded: true,
            initialValue: customCoat ? 'Otro (especificar)'
                : petCoatOptions(species).contains(coat.text) ? coat.text : null,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.tune)),
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
            SizedBox(height: 10),
            TextField(controller: coat,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Describe el pelaje o característica',
                hintText: 'Ej. corto y rizado',
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: petCareActionFooter(
        context,
        FilledButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.check),
          label: Text(saving ? 'Guardando...'
              : widget.existing == null ? 'Agregar mascota' : 'Guardar cambios'),
        ),
      ),
    );
  }
}


/// Panel con superficie Material propia para ListTile y SwitchListTile.
/// Evita ocultar los efectos de selección detrás de un DecoratedBox.
Widget _adminCarePanel(BuildContext context, List<Widget> children) {
  final scheme = Theme.of(context).colorScheme;
  return Material(
    color: scheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
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
          SnackBar(
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
          SnackBar(
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
        title: Text('Eliminar tipo de cuidado'),
        content: Text(
          '¿Eliminar «${careTypeLabel(row)}»?\n\n'
          'Esta opción dejará de aparecer para los usuarios. '
          'Los registros que ya hicieron permanecen en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Sí, eliminar'),
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
          SnackBar(
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
    final scheme = Theme.of(context).colorScheme;
    final shown = items.where((row) {
      final active = row['active'] != false;
      if (speciesFilter != 'Todas') {
        final species = row['species'];
        if (species is! List || !species.contains(speciesFilter)) return false;
      }
      if (statusFilter == 'Visibles' && !active) return false;
      if (statusFilter == 'Ocultos' && active) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de cuidado',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: true,
              child: RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.medical_services_outlined,
                              color: scheme.onPrimaryContainer, size: 27),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Catálogo de cuidados',
                                    style: TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onPrimaryContainer)),
                                const SizedBox(height: 5),
                                Text('Crea, edita y organiza las opciones que verán las personas.',
                                    style: TextStyle(
                                      height: 1.3,
                                      color: scheme.onPrimaryContainer,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: createNew,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Crear nuevo cuidado'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _adminCarePanel(context, [
                      Text('Buscar por especie y estado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          )),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: speciesFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Especie',
                        ),
                        items: ['Todas', ...allPetSpecies]
                            .map((species) => DropdownMenuItem<String>(
                                  value: species,
                                  child: Text(species == 'Todas'
                                      ? 'Todas las especies'
                                      : '${emojiFor(species)}  $species',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => speciesFilter = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          showSelectedIcon: true,
                          segments: const [
                            ButtonSegment(value: 'Todos', label: Text('Todos')),
                            ButtonSegment(value: 'Visibles', label: Text('Visibles')),
                            ButtonSegment(value: 'Ocultos', label: Text('Ocultos')),
                          ],
                          selected: {statusFilter},
                          onSelectionChanged: (selection) {
                            setState(() => statusFilter = selection.first);
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Cuidados existentes',
                              style: TextStyle(fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface)),
                        ),
                        Text('${shown.length} de ${items.length}',
                            style: TextStyle(fontWeight: FontWeight.w700,
                                color: scheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (shown.isEmpty)
                      _adminCarePanel(context, [
                        Text('No hay cuidados con estos filtros.',
                            style: TextStyle(color: scheme.onSurface)),
                        const SizedBox(height: 6),
                        Text('Cambia los filtros o crea una opción nueva.',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ]),
                    ...shown.map((row) {
                      final active = row['active'] != false;
                      final detail =
                          (row['description'] ?? '').toString().trim();
                      final cardColor = scheme.surface;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: active ? scheme.primaryContainer
                                          : scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(careTypeIcon(row),
                                      color: active ? scheme.onPrimaryContainer
                                          : scheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(careTypeLabel(row),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: scheme.onSurface)),
                                        const SizedBox(height: 7),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: active ? scheme.primaryContainer
                                                : scheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(active ? 'Visible' : 'Oculto',
                                              style: TextStyle(fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: active ? scheme.onPrimaryContainer
                                                    : scheme.onSurfaceVariant)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (detail.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(detail, maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: scheme.onSurfaceVariant)),
                              ],
                              const SizedBox(height: 10),
                              Text('Especies: ${speciesText(row)}',
                                  style: TextStyle(fontSize: 13,
                                      color: scheme.onSurfaceVariant)),
                              Divider(height: 24, color: scheme.outlineVariant),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: () => edit(row),
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Editar'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => duplicate(row),
                                      icon: const Icon(Icons.copy_outlined, size: 18),
                                      label: const Text('Duplicar'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => changeActive(row),
                                    icon: Icon(active ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined, size: 19),
                                    label: Text(active ? 'Ocultar' : 'Mostrar'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => remove(row),
                                    icon: const Icon(Icons.delete_outline, size: 19),
                                    label: const Text('Eliminar'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: scheme.error),
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
        SnackBar(
          content: Text('Escribe el nombre del cuidado.'),
        ),
      );
      return;
    }

    if (!allSpecies && selectedSpecies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
          SnackBar(
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
    final scheme = Theme.of(context).colorScheme;
    final modeTitle = editing
        ? 'Editar cuidado'
        : duplicating ? 'Duplicar cuidado' : 'Nuevo cuidado';
    final explanation = editing
        ? 'Estás editando «${careTypeLabel(widget.existing!)}».'
        : duplicating
            ? 'Crearás una copia de «${careTypeLabel(widget.copyFrom!)}».'
            : 'Personaliza la información del cuidado.';
    final previewTitle = label.text.trim().isEmpty
        ? 'Nombre del cuidado' : label.text.trim();
    final previewDescription = description.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(modeTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(editing ? Icons.edit_outlined
                      : duplicating ? Icons.copy_outlined
                          : Icons.add_circle_outline,
                    color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(explanation,
                      style: TextStyle(height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimaryContainer)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _adminCarePanel(context, [
              Text('1. Información del cuidado',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface)),
              const SizedBox(height: 15),
              Text('Nombre',
                  style: TextStyle(fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 7),
              TextField(
                controller: label,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Ej. Medicamento o Paseo',
                ),
              ),
              const SizedBox(height: 16),
              Text('Descripción (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 7),
              TextField(
                controller: description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Describe brevemente este cuidado',
                  alignLabelWithHint: true,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _adminCarePanel(context, [
              Text('2. Especies disponibles',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface)),
              const SizedBox(height: 9),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Todas las especies'),
                subtitle: const Text(
                  'Actívalo para incluirlas todas.',
                ),
                value: allSpecies,
                onChanged: (value) => setState(() => allSpecies = value),
              ),
              if (allSpecies) ...[
                const SizedBox(height: 8),
                Text('Disponible para todas las mascotas.',
                    style: TextStyle(fontSize: 13,
                        color: scheme.onSurfaceVariant)),
              ] else ...[
                const SizedBox(height: 8),
                Text('Selecciona las especies que verán este cuidado:',
                    style: TextStyle(fontSize: 13,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: allPetSpecies.map((species) {
                    return FilterChip(
                      selected: selectedSpecies.contains(species),
                      showCheckmark: true,
                      label: Text('${emojiFor(species)}  $species'),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        selectedSpecies.addAll(allPetSpecies);
                      }),
                      icon: const Icon(Icons.done_all_outlined),
                      label: const Text('Seleccionar todas'),
                    ),
                    TextButton(
                      onPressed: () => setState(selectedSpecies.clear),
                      child: const Text('Limpiar selección'),
                    ),
                  ],
                ),
                Text('${selectedSpecies.length} de ${allPetSpecies.length} especies seleccionadas',
                    style: TextStyle(fontSize: 12,
                        color: scheme.onSurfaceVariant)),
              ],
            ]),
            const SizedBox(height: 14),
            _adminCarePanel(context, [
              Text('3. Visibilidad',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface)),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mostrar a los usuarios'),
                subtitle: const Text(
                  'Si lo ocultas, el historial anterior se conserva.',
                ),
                value: active,
                onChanged: (value) => setState(() => active = value),
              ),
            ]),
            const SizedBox(height: 14),
            _adminCarePanel(context, [
              Text('4. Icono del cuidado',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface)),
              const SizedBox(height: 6),
              Text('Elige cómo se identificará este cuidado.',
                  style: TextStyle(fontSize: 13,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: icon,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Selecciona un icono',
                ),
                items: careIconChoices.entries
                    .map((entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(careIcon(entry.key), size: 22,
                                  color: scheme.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(entry.value,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: scheme.onSurface))),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => icon = value);
                },
              ),
            ]),
            const SizedBox(height: 14),
            _adminCarePanel(context, [
              Text('Vista previa',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(careIcon(icon),
                        color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(previewTitle,
                          softWrap: true,
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface)),
                        if (previewDescription.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(previewDescription,
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(active ? 'Visible para usuarios' : 'Oculto para usuarios',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant)),
                ),
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: petCareActionFooter(
        context,
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Guardando...'
              : editing ? 'Guardar cambios' : 'Crear cuidado'),
        ),
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
        SnackBar(
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
          SnackBar(
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
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.careTypes.isEmpty)
              Card(
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
                decoration: InputDecoration(
                  labelText: 'Tipo de cuidado',
                ),
                items: widget.careTypes
                    .map(
                      (row) => DropdownMenuItem(
                        value: row['id'].toString(),
                        child: Row(
                          children: [
                            Icon(careTypeIcon(row), size: 20),
                            SizedBox(width: 10),
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
            SizedBox(height: 12),
            TextField(
              controller: note,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nota opcional',
                hintText: 'Ej. Dar después de la comida',
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    saving || widget.careTypes.isEmpty ? null : save,
                icon: Icon(Icons.save_outlined),
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
        title: Text('Eliminar registro'),
        content: Text(
          '¿Eliminar este registro de '
          '«${careEntryLabel(row, careTypes)}»?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Eliminar registro'),
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            careTypes.isEmpty ? null : () => editCare(),
        icon: Icon(Icons.add),
        label: Text('Agregar cuidado'),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                Card(
                  color: adaptivePale(context),
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Row(
                      children: [
                        Text(
                          emojiFor(species),
                          style: TextStyle(fontSize: 36),
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                petName,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: adaptiveInk(context),
                                ),
                              ),
                              Text(
                                breed.isEmpty
                                    ? species
                                    : '$species · $breed',
                                style: TextStyle(
                                  color: adaptiveMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Historial de cuidados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: adaptiveInk(context),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Aquí puedes agregar, editar o eliminar '
                  'registros de esta mascota.',
                  style: TextStyle(color: adaptiveMuted(context)),
                ),
                SizedBox(height: 12),
                if (careTypes.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Esta especie no tiene tipos de cuidado visibles. '
                        'Créalo desde Administración → Tipos de cuidado.',
                      ),
                    ),
                  ),
                if (care.isEmpty)
                  Card(
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
                                backgroundColor: adaptivePale(context),
                                child: Icon(
                                  careEntryIcon(row, careTypes),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: 12),
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      (row['time'] ?? '').toString(),
                                      style: TextStyle(
                                        color: adaptiveMuted(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (note.isNotEmpty) ...[
                            SizedBox(height: 10),
                            Text(note),
                          ],
                          Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => editCare(row),
                                  child: Text('Editar'),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => removeCare(row),
                                  child: Text('Eliminar'),
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
