(() => {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const sections = ['auth-loading','auth-form-view','auth-result-view','auth-invalid-view'];
  const show = (id) => sections.forEach(key => { $(key).hidden = key !== id; });
  const invalid = (message) => { $('invalid-message').textContent = message; show('auth-invalid-view'); };
  const result = (title, message) => {
    $('result-title').textContent = title;
    $('result-message').textContent = message;
    show('auth-result-view');
  };
  const params = new URLSearchParams(location.search);
  const mode = params.get('mode');
  const oobCode = params.get('oobCode');
  // Evita que el código de un solo uso quede visible en el historial al abrir la pantalla.
  if (oobCode) window.history.replaceState(null, '', location.pathname);

  if (!mode || !oobCode) {
    invalid('Falta el código de seguridad. Pide un correo nuevo de recuperación desde la aplicación.');
    return;
  }
  if (typeof firebase === 'undefined' || !firebase.apps || !firebase.apps.length) {
    invalid('No fue posible conectar con Firebase. Revisa tu internet e inténtalo de nuevo.');
    return;
  }
  const auth = firebase.auth();
  auth.languageCode = 'es';

  for (const b of document.querySelectorAll('[data-toggle]')) {
    b.addEventListener('click', () => {
      const input = $(b.dataset.toggle);
      input.type = input.type === 'password' ? 'text' : 'password';
      b.textContent = input.type === 'text' ? 'Ocultar' : 'Mostrar';
    });
  }

  const password = $('new-password');
  password.addEventListener('input', () => {
    const value = password.value;
    let score = Number(value.length >= 8) + Number(/[a-z]/.test(value) && /[A-Z]/.test(value)) +
      Number(/[0-9]/.test(value)) + Number(/[^A-Za-z0-9]/.test(value));
    const bar = $('strength-level');
    bar.style.width = (score * 25) + '%';
    bar.style.background = score >= 3 ? '#24a776' : score === 2 ? '#d6a82b' : '#df8250';
  });

  async function resetPassword() {
    try {
      const email = await auth.verifyPasswordResetCode(oobCode);
      $('account-email').textContent = `Cuenta: ${email}`;
      show('auth-form-view');
    } catch (error) {
      invalid('El enlace ha caducado, no es válido o ya fue utilizado. Solicita otro desde la app.');
      return;
    }
    $('reset-form').addEventListener('submit', async (event) => {
      event.preventDefault();
      const msg = $('auth-error');
      const pass = password.value;
      const repeated = $('confirm-password').value;
      const button = $('submit-password');
      msg.hidden = true;
      if (pass.length < 8) { msg.textContent = 'Usa por lo menos 8 caracteres.'; msg.hidden = false; return; }
      if (pass.length > 256) { msg.textContent = 'La contraseña es demasiado larga.'; msg.hidden = false; return; }
      if (pass !== repeated) { msg.textContent = 'Las contraseñas no coinciden.'; msg.hidden = false; return; }
      button.disabled = true;
      button.textContent = 'Actualizando…';
      try {
        await auth.confirmPasswordReset(oobCode, pass);
        $('reset-form').reset();
        result('¡Contraseña actualizada!', 'Ya puedes volver a la aplicación e iniciar sesión con tu nueva contraseña. 🐾');
      } catch (error) {
        msg.textContent = error && error.code === 'auth/weak-password'
          ? 'Elige una contraseña más segura y vuelve a intentarlo.'
          : 'No pudimos actualizar la contraseña. Solicita un enlace nuevo e inténtalo otra vez.';
        msg.hidden = false;
      } finally {
        button.disabled = false;
        button.textContent = 'Actualizar contraseña';
      }
    });
  }

  async function verifyEmail() {
    try { await auth.applyActionCode(oobCode); result('¡Correo verificado!', 'Tu dirección de correo electrónico se verificó correctamente.'); }
    catch (error) { invalid('La verificación no se pudo completar. Solicita un enlace nuevo desde la aplicación.'); }
  }
  async function recoverEmail() {
    try {
      await auth.checkActionCode(oobCode);
      await auth.applyActionCode(oobCode);
      result('Correo recuperado', 'La dirección de correo de tu cuenta fue restaurada correctamente.');
    } catch (error) { invalid('El enlace de recuperación de correo no se pudo validar. Solicita otro enlace.'); }
  }
  switch (mode) {
    case 'resetPassword': resetPassword(); break;
    case 'verifyEmail': verifyEmail(); break;
    case 'recoverEmail': recoverEmail(); break;
    default: invalid('El tipo de solicitud no es compatible con esta página.');
  }
})();
