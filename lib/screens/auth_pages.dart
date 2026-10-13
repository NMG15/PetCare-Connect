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
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset('assets/icon/petcare_icon.png',
                    width: 126, height: 126, fit: BoxFit.contain),
                ),
                SizedBox(height: 28),
                Text('PetCare Connect',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: adaptiveInk(context))),
                SizedBox(height: 12),
                Text('Todo el cuidado de tus mascotas, en un solo lugar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: adaptiveMuted(context))),
                const Spacer(),
                SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AuthPage(login: true))),
                        child: Text('Iniciar sesión'))),
                SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AuthPage(login: false))),
                        child: Text('Crear cuenta'))),
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
    return 'No se pudo continuar con $provider. Revisa el diagnóstico en la app.';
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

  Future<void> showFacebookDiagnostic(String detail) async {
    if (!mounted) return;
    final safeDetail = redactDiagnostic(detail);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 34),
        title: Text('Diagnóstico de Facebook'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Este informe ayuda a distinguir los errores de la APK '
                  'de los bloqueos de acceso de Meta. Si Facebook muestra '
                  '«La app no está activa», no se soluciona cambiando una API Key.'),
              SizedBox(height: 14),
              SelectableText(safeDetail, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: safeDetail));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              msg('Diagnóstico copiado. Revísalo antes de compartirlo.');
            },
            icon: Icon(Icons.copy),
            label: Text('Copiar diagnóstico'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
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
        _ => 'No se pudo iniciar sesión. ${e.message ?? ''}',
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
        msg('Google no pudo iniciar sesión (${e.code.name}). '
          'Comprueba Google Play Services y las firmas SHA en Firebase.');
      }
    } on FirebaseAuthException catch (e) {
      msg('Firebase no pudo iniciar sesión con Google: ${e.message ?? e.code}');
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
        if (sdkMessage.isEmpty) {
          msg('Acceso con Facebook cancelado. Si viste «La app no está activa», '
              'es un bloqueo de Meta y debes revisar su estado de acceso.');
        } else {
          await showFacebookDiagnostic(
            'Inicio cancelado por Facebook.\n'
            'Mensaje: $sdkMessage\n'
            'Método: navegador (webOnly)',
          );
        }
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
    } on FirebaseAuthException catch (e) {
      msg('No se pudo enviar el correo: ${e.message ?? e.code}');
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
