part of '../main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data == null ? const WelcomePage() : const HomePage();
        },
      );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewport.maxHeight > 56
                      ? viewport.maxHeight - 56
                      : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'BIENVENIDO A PETCARE',
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          height: 230,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.primaryContainer,
                                colors.surfaceContainerHigh,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icon/petcare_icon.png',
                              width: 145,
                              height: 145,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'PetCare Connect',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Todo lo que necesitas para cuidar a tus mascotas, en un solo lugar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            Chip(
                              avatar: Icon(Icons.pets, size: 18),
                              label: Text('Mascotas'),
                            ),
                            Chip(
                              avatar: Icon(Icons.favorite_outline, size: 18),
                              label: Text('Cuidados'),
                            ),
                            Chip(
                              avatar: Icon(Icons.notifications_none, size: 18),
                              label: Text('Recordatorios'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Iniciar sesión'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthPage(login: true),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Crear cuenta'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthPage(login: false),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'El bienestar de tus mascotas comienza aquí.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
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

  void msg(String text) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      content: Text(text),
      action: SnackBarAction(
        label: 'Cerrar',
        onPressed: messenger.hideCurrentSnackBar,
      ),
    ));
  }

  // Mostrar información útil sin publicar datos sensibles ni credenciales.
  String socialErrorMessage(Object error, String provider) {
    final message = error.toString().toLowerCase();
    if (message.contains('network') || message.contains('internet') ||
        message.contains('socketexception')) {
      return 'No hay conexión estable. Comprueba internet e inténtalo otra vez.';
    }
    if (message.contains('app is not active') ||
        message.contains('app not active') ||
        message.contains('la app no está activa') ||
        message.contains('application is not active')) {
      return 'Meta indica que esta aplicación no está activa para esta sesión. '
          'Comprueba el estado del inicio de sesión en Meta y la cuenta usada en Facebook.';
    }
    if (message.contains('key hash') || message.contains('keyhash')) {
      return 'Firma de Facebook no reconocida (Key Hash). Revisa Meta Developers.';
    }
    if (message.contains('invalid_client_token') || message.contains('client token')) {
      return 'El token de cliente de Facebook es inválido. Revisa Meta Developers.';
    }
    if (message.contains('not initialized') || message.contains('sdk') ||
        message.contains('missingplugin')) {
      return 'No se pudo iniciar el servicio de $provider en este dispositivo.';
    }
    return 'No se pudo continuar con $provider. Inténtalo de nuevo.';
  }

  String redactDiagnostic(String message) => message
      .replaceAllMapped(
        RegExp(r'(access[_-]?token|id[_-]?token|client[_-]?secret)\s*[:=]\s*[^\s,;]+', caseSensitive: false),
        (match) => '${match.group(1)}=[oculto]',
      )
      .replaceAllMapped(
        RegExp(r'([?&](?:code|oobCode|access_token)=)[^&\s]+', caseSensitive: false),
        (match) => '${match.group(1)}[oculto]',
      );

  // No interrumpir el inicio de sesión con un cuadro de diagnóstico técnico.
  // La configuración de Meta sigue siendo necesaria para habilitar Facebook.
  Future<void> showFacebookDiagnostic(String detail) async {
    if (!mounted) return;
    msg('No se pudo iniciar sesión con Facebook por ahora. '
        'Puedes usar tu correo o Google mientras se revisa el acceso.');
  }


  Future<void> emailAuth() async {
    if (email.text.trim().isEmpty || pass.text.isEmpty ||
        (!widget.login && (pass.text.length < 8 || name.text.trim().isEmpty))) {
      msg(widget.login
          ? 'Escribe tu correo y contraseña para iniciar sesión.'
          : 'Completa tu nombre y correo. La contraseña debe tener al menos 8 caracteres.');
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
        try {
          await CloudDb.instance.saveUserProfile(
            credential.user!, name: widget.login ? null : name.text,
          );
        } on FirebaseException catch (e) {
          debugPrint('No se pudo sincronizar el perfil: ${e.code}');
          // La sesión es válida. La pantalla principal reintentará al tener red.
        }
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
        _ => 'No se pudo iniciar sesión. Comprueba tus datos e inténtalo de nuevo.',
      };
      msg(message);
    } on FirebaseException catch (e) {
      debugPrint('AUTH_PROFILE_SYNC_ERROR: ${e.code}');
      msg('No se pudo sincronizar el perfil. Revisa tu conexión.');
    } catch (e) {
      debugPrint('EMAIL_AUTH_ERROR: ${e.runtimeType}');
      msg(socialErrorMessage(e, 'el correo electrónico'));
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
      if (result.user != null) {
        try {
          await CloudDb.instance.saveUserProfile(result.user!);
        } on FirebaseException catch (e) {
          debugPrint('GOOGLE_PROFILE_SYNC_ERROR: ${e.code}');
        }
      }
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on GoogleSignInException catch (e) {
      if (mounted && e.code != GoogleSignInExceptionCode.canceled) {
        debugPrint('GOOGLE_SIGN_IN_ERROR: ${e.code}');
        msg('No pudimos iniciar sesión con Google. Comprueba los servicios de Google y vuelve a intentarlo.');
      }
    } on FirebaseAuthException {
      msg('No se pudo iniciar sesión con Google por ahora. Inténtalo de nuevo.');
    } catch (e) {
      debugPrint('GOOGLE_UNEXPECTED_ERROR: ${e.runtimeType}: $e');
      msg(socialErrorMessage(e, 'Google'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> facebookAuth() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      // Diagnóstico: probar el flujo web evita depender del selector nativo de
      // Facebook y ayuda a confirmar si la restricción proviene de Meta.
      // No desactiva requisitos de publicación o permisos de Meta.
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        loginBehavior: LoginBehavior.webOnly,
      );
      if (!mounted) return;

      final sdkMessage = (result.message ?? '').trim();
      if (result.status == LoginStatus.cancelled) {
        // Cerrar el navegador no debe abrir otro aviso técnico encima.
        return;
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        await showFacebookDiagnostic(
          'Estado del SDK: ${result.status.name}\n'
          'Mensaje: ${sdkMessage.isEmpty ? 'Sin descripción' : sdkMessage}\n'
          'Método: navegador (webOnly)\n'
          'Paquete: com.petcareconnect.app\n'
          'Compilación: ${amazonBuild ? 'Amazon Fire' : 'Android'}',
        );
        return;
      }

      // Nunca mostramos, copiamos ni imprimimos tokens de acceso.
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      final signedIn = await FirebaseAuth.instance.signInWithCredential(credential);
      if (signedIn.user != null) {
        try {
          await CloudDb.instance.saveUserProfile(signedIn.user!);
        } on FirebaseException catch (e) {
          debugPrint('FACEBOOK_PROFILE_SYNC_ERROR: ${e.code}');
        }
      }
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      debugPrint('FACEBOOK_FIREBASE_ERROR: ${e.code}');
      final detail = switch (e.code) {
        'account-exists-with-different-credential' =>
          'Ya existe una cuenta con este correo usando otro proveedor.',
        'credential-already-in-use' =>
          'Esta cuenta de Facebook ya está asociada a otra cuenta.',
        'operation-not-allowed' =>
          'El proveedor Facebook no está habilitado correctamente en Firebase.',
        _ => 'Firebase Auth: ${e.code}; ${e.message ?? 'Sin descripción'}',
      };
      await showFacebookDiagnostic(detail);
    } catch (e, stackTrace) {
      final descripcion = redactDiagnostic(e.toString());
      debugPrint('FACEBOOK_LOGIN_ERROR: ${e.runtimeType}: $descripcion');
      debugPrintStack(stackTrace: stackTrace);
      await showFacebookDiagnostic(
        'Tipo: ${e.runtimeType}\n'
        'Causa: ${socialErrorMessage(e, 'Facebook')}\n'
        'Descripción técnica: $descripcion',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    final value = email.text.trim();
    if (value.isEmpty) { msg('Escribe tu correo primero.'); return; }
    try {
      await FirebaseAuth.instance.setLanguageCode('es');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: value);
      if (mounted) msg('Te enviamos un correo para restablecer tu contraseña.');
    } on FirebaseAuthException {
      msg('No se pudo enviar el correo de recuperación. Revisa la dirección e inténtalo otra vez.');
    } catch (e) {
      debugPrint('PASSWORD_RESET_ERROR: ${e.runtimeType}');
      msg(socialErrorMessage(e, 'el correo de recuperación'));
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
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset('assets/icon/petcare_icon.png',
            height: 68, width: 68, fit: BoxFit.contain),
        ),
        SizedBox(height: 18),
        Text(widget.login ? 'Bienvenido de nuevo' : 'Crea tu cuenta', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(widget.login ? 'Tus mascotas se sincronizan de forma segura en la nube.' : 'Crea una cuenta para guardar tus mascotas en la nube.', style: TextStyle(color: adaptiveMuted(context))),
        SizedBox(height: 30),
        if (!widget.login) ...[
          TextField(controller: name, decoration: InputDecoration(labelText: 'Tu nombre', prefixIcon: Icon(Icons.person_outline))),
          SizedBox(height: 14),
        ],
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined))),
        SizedBox(height: 14),
        TextField(
          controller: pass,
          obscureText: !showPassword,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
              onPressed: () => setState(() => showPassword = !showPassword),
              icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
          ),
        ),
        if (widget.login) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : resetPassword, child: Text('¿Olvidaste tu contraseña?'))),
        SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 55, child: FilledButton(onPressed: busy ? null : emailAuth, child: Text(busy ? 'Espera...' : widget.login ? 'Iniciar sesión' : 'Crear cuenta'))),
        if (!amazonBuild || amazonFacebookEnabled) ...[
          SizedBox(height: 18),
          Row(children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o')),
            Expanded(child: Divider()),
          ]),
          SizedBox(height: 18),
        ],
        if (!amazonBuild) ...[
          SizedBox(width: double.infinity, height: 55,
            child: OutlinedButton.icon(
              onPressed: busy ? null : googleAuth,
              icon: Icon(Icons.account_circle_outlined),
              label: Text('Continuar con Google'),
            ),
          ),
          SizedBox(height: 12),
        ],
        if (!amazonBuild || amazonFacebookEnabled)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: busy ? null : facebookAuth,
              icon: Icon(Icons.facebook),
              label: Text('Continuar con Facebook'),
            ),
          ),
        if (amazonBuild && !amazonFacebookEnabled)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'En Fire Tablet puedes entrar con tu correo y contraseña. '
              'Los accesos sociales estarán disponibles después de verificar '
              'su compatibilidad con este dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: adaptiveMuted(context), fontSize: 13),
            ),
          ),
      ]),
    ),
  );
}
