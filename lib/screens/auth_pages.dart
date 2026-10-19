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
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(child: LayoutBuilder(builder: (context, size) =>
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.maxHeight > 62 ? size.maxHeight - 62 : 0,
            ),
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: c.primaryContainer,
                        borderRadius: BorderRadius.circular(30)),
                      child: Text('✦  TODO SU MUNDO, EN TUS MANOS',
                        style: TextStyle(color: c.onPrimaryContainer,
                          fontSize: 10.5, fontWeight: FontWeight.w900,
                          letterSpacing: 0.9)),
                    )),
                  const SizedBox(height: 22),
                  Container(
                    height: 232,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.primaryContainer, c.surfaceContainerHigh],
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(child: Image.asset(
                      'assets/icon/petcare_icon.png',
                      width: 148, height: 148, fit: BoxFit.contain,
                    )),
                  ),
                  const SizedBox(height: 23),
                  RichText(textAlign: TextAlign.center, text: TextSpan(children: [
                    TextSpan(text: 'Amor que se cuida\n', style: TextStyle(
                      fontSize: 34, height: 1.15, letterSpacing: -1.1,
                      fontWeight: FontWeight.w900, color: c.onSurface)),
                    TextSpan(text: 'cada día.', style: TextStyle(
                      fontSize: 34, height: 1.15, letterSpacing: -1.1,
                      fontWeight: FontWeight.w900, color: c.primary)),
                  ])),
                  const SizedBox(height: 15),
                  Text('Sus cuidados, vacunas y recuerdos. Todo organizado '
                    'para disfrutar más tiempo juntos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.onSurfaceVariant,
                      fontSize: 15.5, height: 1.5)),
                  const SizedBox(height: 20),
                  Wrap(alignment: WrapAlignment.center, spacing: 7,
                    runSpacing: 7, children: const [
                      Chip(avatar: Icon(Icons.pets_rounded, size: 17),
                        label: Text('Mascotas')),
                      Chip(avatar: Icon(Icons.favorite_outline, size: 17),
                        label: Text('Cuidados')),
                      Chip(avatar: Icon(Icons.notifications_none, size: 17),
                        label: Text('Avisos')),
                    ]),
                  const SizedBox(height: 25),
                  SizedBox(height: 56, child: FilledButton.icon(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuthPage(login: true))),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Iniciar sesión'),
                  )),
                  const SizedBox(height: 12),
                  SizedBox(height: 54, child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuthPage(login: false))),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Crear cuenta'),
                  )),
                  const SizedBox(height: 20),
                  Text('PetCare Connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            )),
          ),
        ),
      )),
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLogin = widget.login;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(''),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primaryContainer,
                            colors.surfaceContainerHigh,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/icon/petcare_icon.png',
                              width: 74,
                              height: 74,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PETCARE CONNECT',
                                  style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Un espacio para cuidarlos',
                                  style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      isLogin
                          ? 'Qué bueno tenerte aquí.'
                          : 'Comencemos juntos.',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isLogin
                          ? 'Inicia sesión para continuar cuidando a tus mascotas.'
                          : 'Crea tu cuenta y organiza el cuidado de tus mascotas.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colors.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isLogin
                                ? 'Accede a tu espacio'
                                : 'Crea tu espacio',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (!isLogin) ...[
                            TextField(
                              controller: name,
                              textCapitalization:
                                  TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.name
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Tu nombre',
                                prefixIcon:
                                    Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextField(
                            controller: email,
                            keyboardType:
                                TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.email
                            ],
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon:
                                  Icon(Icons.email_outlined),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: pass,
                            obscureText: !showPassword,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            autofillHints: isLogin
                                ? const [AutofillHints.password]
                                : const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon:
                                  const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: showPassword
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                onPressed: () => setState(
                                  () => showPassword = !showPassword,
                                ),
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),

                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    busy ? null : resetPassword,
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                ),
                              ),
                            ),

                          const SizedBox(height: 18),

                          SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: busy ? null : emailAuth,
                              icon: Icon(
                                isLogin
                                    ? Icons.login_rounded
                                    : Icons.person_add_alt_1,
                              ),
                              label: Text(
                                busy
                                    ? 'Espera...'
                                    : isLogin
                                        ? 'Iniciar sesión'
                                        : 'Crear cuenta',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!amazonBuild ||
                        amazonFacebookEnabled) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            child: Text(
                              'o continúa con',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (!amazonBuild) ...[
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : googleAuth,
                          icon: const Icon(
                            Icons.account_circle_outlined,
                          ),
                          label: const Text(
                            'Continuar con Google',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!amazonBuild ||
                        amazonFacebookEnabled)
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : facebookAuth,
                          icon: const Icon(Icons.facebook),
                          label: const Text(
                            'Continuar con Facebook',
                          ),
                        ),
                      ),

                    if (amazonBuild &&
                        !amazonFacebookEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'En Fire Tablet puedes acceder con '
                          'correo y contraseña. Los accesos '
                          'sociales estarán disponibles '
                          'después de verificar su compatibilidad.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(height: 22),

                    TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AuthPage(
                                    login: !isLogin,
                                  ),
                                ),
                              ),
                      child: Text(
                        isLogin
                            ? '¿No tienes cuenta? Regístrate'
                            : '¿Ya tienes cuenta? Inicia sesión',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'El bienestar de tus mascotas '
                      'comienza aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
