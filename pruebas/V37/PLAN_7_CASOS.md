# ✅ Plan breve de pruebas — PetCare Connect V37

**Seis casos obligatorios**, más **uno opcional**. No se necesita probar cada botón. Marca `Correcto`, `Error` o `No probado` en tu informe personal y explica brevemente el resultado.

| Caso | Área que cubre | Qué hacer | Resultado esperado |
|:--|:--|:--|:--|
| **PC-01** | Instalación y acceso | Abrir APK V37, recorrer bienvenida e iniciar sesión con cuenta propia. Revisar el acceso a **¿Olvidaste tu contraseña?**; pedir un correo de recuperación **solo con cuenta propia** si está autorizado. | App abre, inicio de sesión funciona; el flujo de recuperación presenta instrucciones comprensibles, sin exponer información. |
| **PC-02** | Mascotas | Consultar lista y perfil; **si hay permiso**, crear y editar una mascota de prueba propia. | Información y botones se muestran sin fallos, la lista refleja los cambios autorizados. |
| **PC-03** | Cuidados | Revisar Agua, Alimentación, etc., sus estados y personalización. **Si hay permiso**, registrar un cuidado, cambiar nombre/icono de base y añadir uno personalizado en una mascota de prueba. | Tarjetas alineadas, estados claros; los cuidados se diferencian y los cambios permitidos se guardan. |
| **PC-04** | Horarios y avisos | Ver y, **si hay permiso**, configurar o modificar un aviso con hora/días para una mascota de prueba. Registrar si el teléfono notifica y anotar la diferencia de tiempo cuando sea posible. | El horario queda visible, no aparecen duplicados inesperados; el aviso se recibe o se reporta exactamente lo observado. |
| **PC-05** | Historial y calendario | Revisar historial de cuidados y navegar fechas. | Fechas correctas, registros disponibles y navegación estable. |
| **PC-06** | Interfaz | Cambiar claro/oscuro, abrir configuración y recorrer pantallas principales. | Texto, tarjetas, botones y menús legibles, alineados y sin superposiciones. |
| **PC-07** *(opcional)* | Administración y permisos | Con cuenta de prueba que tenga rol autorizado, entrar al panel; con cuenta normal, comprobar que no aparezcan acciones reservadas. | Acciones del panel coherentes con permisos; ningún acceso de administración no autorizado. |

**Sobre recordatorios:** Android puede demorar avisos según batería y permisos. No marques `Error` solo por no esperar el horario; anota `No probado` o el retraso observado. Si aparece un fallo, registra: qué tocaste → qué esperabas → qué ocurrió, con pasos breves para reproducirlo.

**Tiempo:** 15-25 minutos para las seis pruebas obligatorias. Los casos con escritura necesitan autorización: no modificar datos de producción de terceros.
