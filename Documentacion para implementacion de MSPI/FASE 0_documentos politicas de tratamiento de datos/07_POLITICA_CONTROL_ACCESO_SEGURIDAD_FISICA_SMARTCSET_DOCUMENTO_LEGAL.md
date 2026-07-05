# POLÍTICA DE CONTROL DE ACCESO Y SEGURIDAD FÍSICA

## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo                                  | Valor                                                                            |
| -------------------------------------- | -------------------------------------------------------------------------------- |
| **Documento N°**                | FASE0-ACC-007                                                                    |
| **Versión**                     | 1.0                                                                              |
| **Fecha de elaboración**        | 2026-06-08                                                                       |
| **Elaborado por**                | Equipo de Desarrollo - SmartCSET                                                 |
| **Estado**                       | Borrador para revisión y aprobación por la Dirección del Centro de Formación |
| **Próxima revisión**           | Anual, o ante cambio en la estructura de accesos o en la infraestructura física |
| **Clasificación del documento** | Uso institucional — Difusión controlada                                        |

---

> ⚠️ **Nota de gobernanza esencial:** El control de acceso es la primera línea de defensa de SmartCSET. Sin una política formal que defina quién puede acceder a qué, bajo qué condiciones y con qué controles, los demás controles técnicos —cifrado, rate limiting, auditorías— pierden gran parte de su eficacia. Esta Política desarrolla dos dimensiones inseparables del control de acceso: la **lógica** (quién puede entrar al sistema, qué puede hacer dentro de él, cómo se gestionan sus credenciales) y la **física** (quién puede acceder al espacio donde viven los servidores y los datos). Ambas son requisitos del MSPI de MinTIC (Ejes 5 y 7), de la norma ISO/IEC 27001 (Annex A, controles 5.15 a 5.23 y 7.1 a 7.13) y del temario ISC2 CC (Dominio 3 — Access Controls). Cada sección marcada con 🔲 requiere validación o complemento por la instancia directiva y técnica competente antes de su aprobación oficial.

---

---

## 1. OBJETO Y ALCANCE

### 1.1 Objeto

Esta Política tiene por objeto establecer los **principios, requisitos y procedimientos** que rigen el control de acceso al sistema SmartCSET —tanto en su dimensión lógica (acceso a la aplicación, a la base de datos y a los servidores) como en su dimensión física (acceso a los espacios donde se aloja la infraestructura del sistema)— con el fin de garantizar que solo las personas debidamente autorizadas accedan a los activos de información del sistema, y que lo hagan únicamente en la medida necesaria para cumplir sus funciones institucionales.

### 1.2 Alcance

Esta Política aplica a:

- **Todos los usuarios del sistema SmartCSET**: personal de portería, personal de registro de personas, administradores del sistema, coordinadores y cualquier otra persona con credenciales de acceso activas.
- **El personal técnico con acceso directo** a la base de datos PostgreSQL, al servidor de aplicación o a la infraestructura de red del sistema: Administrador del sistema, personal de la Oficina de TI del SENA, desarrolladores con acceso de soporte.
- **Terceros con acceso autorizado temporal**: personal externo de soporte, auditores, personal de mantenimiento de infraestructura.
- **Los espacios físicos** donde se aloja la infraestructura de SmartCSET: cuarto de servidores, sala de equipos de red y cualquier otro espacio de la instalación del SENA donde resida hardware crítico del sistema.
- **Los equipos terminales** utilizados para operar el sistema: computadores de portería, equipos administrativos con acceso a SmartCSET, dispositivos de captura fotográfica integrados al sistema.

### 1.3 Lo que esta Política NO cubre

- No regula el control de acceso físico de las personas que ingresan al Centro de Formación (esa es la función operativa de SmartCSET, no el objeto de esta Política).
- No reemplaza los procedimientos de control físico de la infraestructura que son responsabilidad exclusiva de la Oficina de TI del SENA para la infraestructura institucional general.

---

## 2. MARCO NORMATIVO APLICABLE

| Norma                                            | Contenido relevante para esta Política                                                                                                                                         |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ley 1581 de 2012, art. 17(b)**           | Obligación del Responsable de permitir el acceso a los datos personales solo a personas autorizadas y establecer mecanismos de control sobre quién accede                     |
| **Ley 1273 de 2009, art. 269A**            | Tipifica penalmente el acceso abusivo a sistemas informáticos — la política de control de acceso es la primera medida de prevención de esta conducta                        |
| **Decreto 1078 de 2015 (DUR-TIC) — MSPI** | Eje 7 (Control de Acceso): las entidades deben definir y aplicar políticas de control de acceso lógico y físico a sus sistemas de información                               |
| **MSPI MinTIC — Eje 5**                   | Seguridad Física y del Entorno: protección de instalaciones y equipos que procesan información institucional                                                                 |
| **ISO/IEC 27001:2022 — Annex A**          | Controles 5.15–5.23 (gestión de identidades y accesos), 5.18 (derechos de acceso), 7.1–7.4 (seguridad física de instalaciones), 7.6–7.9 (seguridad de equipos)             |
| **CONPES 3995 de 2020**                    | Gestión activa de identidades y accesos como parte de la postura de seguridad digital de las entidades públicas                                                               |
| **FASE0-PSI-006**                          | Política General de Seguridad de la Información — esta Política desarrolla el principio de mínimo privilegio (Sección 4.2) y los objetivos O-01 y O-04 de dicha Política |

---

## 3. DEFINICIONES

| Término                                           | Definición                                                                                                                                                        | Aplicación en SmartCSET                                                                                                                                       |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Control de acceso lógico**                | Conjunto de mecanismos que regulan quién puede autenticarse en un sistema de información y qué operaciones puede realizar dentro de él                         | Autenticación con usuario/contraseña en `index.php`; asignación de menús y permisos en `tab_menu_usuarios`; indicador de administrador `ind_usuario` |
| **Control de acceso físico**                | Medidas que restringen el acceso físico a espacios, equipos o medios donde se procesa o almacena información                                                     | Acceso al cuarto de servidores, a los equipos de portería, a los medios de almacenamiento con copias de seguridad                                             |
| **Autenticación**                           | Proceso de verificar que una entidad (persona, proceso o sistema) es quien dice ser                                                                                | Validación de usuario y contraseña bcrypt en el login de SmartCSET                                                                                           |
| **Autorización**                            | Proceso de determinar qué operaciones puede realizar una entidad ya autenticada                                                                                   | Menús y módulos asignados al usuario en `tab_menu_usuarios`; flag `ind_usuario` para funciones de administrador                                          |
| **Control de acceso basado en roles (RBAC)** | Modelo de control de acceso donde los permisos se asignan a roles y los roles se asignan a usuarios, en lugar de asignar permisos directamente a cada usuario      | En SmartCSET: dos niveles base (usuario operativo / administrador), con granularidad adicional a nivel de menús asignados individualmente                     |
| **Principio de mínimo privilegio**          | Cada usuario, proceso o sistema tiene acceso solo a los recursos estrictamente necesarios para cumplir su función, y no más                                      | Un operador de portería no puede acceder al módulo de usuarios ni a la configuración del sistema; el usuario PHP de la BD no tiene privilegios DDL          |
| **Segregación de funciones (SoD)**          | Ninguna persona tiene control completo sobre un proceso crítico de principio a fin, para reducir el riesgo de fraude o error no detectado                         | El Administrador del sistema no puede ser simultáneamente el auditor del mismo sistema; quien registra personas no puede modificar su propio perfil de acceso |
| **Cuenta privilegiada**                      | Cuenta con permisos superiores a los de un usuario estándar: administrador del sistema, superusuario de base de datos, acceso a configuración de infraestructura | `admin.smart` (administrador SmartCSET), usuario `postgres` de la BD, acceso SSH al servidor                                                               |
| **Zona de acceso restringido**               | Espacio físico cuyo ingreso está limitado exclusivamente al personal con función que lo requiera                                                                | Cuarto de servidores del Centro de Formación; área técnica de la Oficina de TI                                                                              |

---

## 4. PRINCIPIOS RECTORES DEL CONTROL DE ACCESO

### 4.1 Mínimo privilegio (*Least Privilege*)

Todo acceso —lógico o físico— se otorga en la cantidad mínima necesaria para cumplir la función asignada. Ningún usuario accede a módulos, datos o espacios que no necesita para su trabajo diario. Este principio se aplica en el diseño del sistema (granularidad de menús), en la administración de cuentas (asignación selectiva de permisos) y en la configuración de la base de datos (usuario PHP de la aplicación con permisos limitados).

### 4.2 Necesidad de conocer (*Need-to-Know*)

Complementario al mínimo privilegio: aunque técnicamente un usuario pudiera tener acceso a cierta información, solo accede a ella si su función institucional lo requiere. La curiosidad, la conveniencia o la jerarquía no son criterios de autorización de acceso.

### 4.3 Segregación de funciones (*Separation of Duties*)

Las funciones críticas del sistema se distribuyen entre personas distintas para evitar que una sola persona tenga control completo sobre un proceso sensible:

| Función 1                       | Función 2                           | Por qué no deben coincidir en la misma persona                                                 |
| -------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------- |
| Registrar personas en el sistema | Administrar los usuarios del sistema | Quien registra personas no puede crear su propio acceso con privilegios elevados                |
| Administrar el sistema           | Auditar el sistema                   | El administrador no puede ser juez de sus propias acciones                                      |
| Aprobar accesos                  | Usarlos                              | Quien aprueba que alguien tenga un permiso no debería ser el mismo que lo otorga técnicamente |

### 4.4 Responsabilidad individual (*Individual Accountability*)

Cada acción relevante en SmartCSET es atribuible a un usuario individual identificado. Las cuentas compartidas están prohibidas. Esto garantiza la trazabilidad completa de quién hizo qué y cuándo, como requisito de auditoría.

### 4.5 Denegación por defecto (*Default Deny*)

Lo que no está expresamente permitido, está denegado. Un usuario recién creado sin menús asignados no puede hacer nada en el sistema. Los permisos se otorgan explícitamente; nunca se hereda un acceso por defecto.

---

## 5. CONTROL DE ACCESO LÓGICO — GESTIÓN DE IDENTIDADES Y ACCESOS

### 5.1 Modelo de control de acceso de SmartCSET

SmartCSET implementa un modelo **RBAC de dos niveles con granularidad de menús**:

| Nivel                               | Descripción técnica                                                                                                                                             | Usuarios típicos                                                                                           |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Usuario operativo**         | `ind_usuario = FALSE` en `tab_usuarios`. Accede solo a los menús asignados en `tab_menu_usuarios` para su cuenta específica                               | Personal de portería, operadores de registro, coordinadores con acceso limitado                            |
| **Administrador del sistema** | `ind_usuario = TRUE` en `tab_usuarios`. Accede a todos los módulos del sistema, incluyendo gestión de usuarios, configuración, menús y reportes avanzados | Administrador técnico del sistema (Equipo de Desarrollo - SmartCSET); en producción, máximo 1-4 personas |

La asignación de menús es **individual**: cada usuario operativo tiene exactamente los menús que necesita para su función, y ninguno más. El módulo `backend/routers/menus/v1/menu_usuarios.php` permite al Administrador asignar, revocar y copiar perfiles de menú entre usuarios.

### 5.2 Proceso de autenticación

| Paso                                 | Mecanismo                                                                           | Implementación en SmartCSET                                                                                           | Estado |
| ------------------------------------ | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------ |
| **Identificación**            | El usuario ingresa su nombre de usuario                                             | Campo `txt_usuario` en `index.php`                                                                                 | ✅ Implementado |
| **Autenticación**             | El sistema verifica la contraseña contra el hash almacenado                        | `password_verify()` con bcrypt en `tab_usuarios.pass_usuario`                                                      | ✅ Implementado |
| **Registro de sesión**        | Cada inicio de sesión se registra con la IP de origen, y la sesión se invalida si la IP de las peticiones deja de coincidir con la del inicio | Registro en `tab_sesiones` vía `accesoIngresoSesion()` en `index.php`; validación de IP por petición | ✅ Implementado |
| **Control de intentos**        | Se registran los intentos fallidos y se bloquea la IP temporalmente tras N intentos | Tabla `tab_intentos_login` — `fun_registrar_intento_login()` / `fun_verificar_bloqueo_ip()`                     | 🔲 Pendiente — Fase 1 E3 (FASE1-BLI-001) |
| **Establecimiento de sesión** | Se crea una sesión segura con ID regenerado y flags de cookie                      | `session_regenerate_id(true)` tras autenticación exitosa; cookies con `HttpOnly`, `Secure`, `SameSite=Strict` | 🔲 Pendiente — Fase 1 E4 (el código existe en `SecurityMiddleware.php` pero aún no está activo en el flujo) |
| **Autorización**              | Se determina qué menús y módulos puede ver el usuario autenticado                | Consulta a `tab_menu_usuarios` con el `id_usuario` de la sesión                                                   | ✅ Implementado |

> ⚠️ Los pasos marcados 🔲 describen el **diseño objetivo** del proceso de autenticación. Su implementación técnica está planificada y especificada en la Fase 1 del Plan de Blindaje (documento FASE1-BLI-001, entregables E3 y E4). Hasta su entrada en operación, el proceso vigente consta únicamente de los pasos marcados ✅.

### 5.3 Identificadores de usuario

- **Un usuario, una cuenta.** No se crean cuentas genéricas ni compartidas (ej: `porteria_general`, `admin_turno`). Cada persona que opera el sistema tiene su propia cuenta nominal.
- Los identificadores de usuario (`id_usuario` en `tab_usuarios`) son únicos, no reutilizables. Cuando un usuario se desvincula, su cuenta se desactiva (`ind_estado = FALSE`), nunca se elimina, para preservar la trazabilidad histórica.
- El nombre de usuario no debe contener información sensible (número de documento, fecha de nacimiento).

### 5.4 Acceso de la aplicación a la base de datos

El usuario PHP que utiliza SmartCSET para conectarse a PostgreSQL debe tener **únicamente** los permisos necesarios para la operación de la aplicación:

| Permiso                                                                           | ¿Necesario? | Justificación                                                                                            |
| --------------------------------------------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------- |
| `SELECT`, `INSERT`, `UPDATE`, `DELETE` sobre las tablas de la aplicación | ✅ Sí       | Operación normal del sistema                                                                             |
| `EXECUTE` sobre las funciones PL/pgSQL del esquema de la aplicación            | ✅ Sí       | Toda la lógica crítica está en funciones PL/pgSQL                                                      |
| `CREATE TABLE`, `DROP TABLE`, `ALTER TABLE` (DDL)                           | ❌ No        | Las migraciones las ejecuta el Administrador manualmente con `psql`, nunca la aplicación en ejecución |
| `SUPERUSER`, `CREATEDB`, `CREATEROLE`                                       | ❌ No        | Nunca — el usuario de la aplicación no necesita privilegios de sistema                                  |

🔲 **Verificar y corregir si es necesario:** ejecutar `SELECT * FROM information_schema.role_table_grants WHERE grantee = 'usuario_de_la_aplicacion';` para confirmar que el usuario PHP no tiene privilegios DDL.

---

## 6. POLÍTICA DE CONTRASEÑAS

### 6.1 Requisitos de contraseñas para usuarios del sistema

| Requisito                                      | Valor mínimo                                                                                    | Justificación                                                                                   |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| **Longitud mínima**                     | 10 caracteres                                                                                    | Reduce exponencialmente el espacio de búsqueda de ataques de fuerza bruta                       |
| **Complejidad**                          | Al menos una mayúscula, una minúscula, un dígito y un carácter especial (`!@#$%^&*`)       | Previene contraseñas de diccionario simples                                                     |
| **Prohibición de contraseñas comunes** | No se aceptan contraseñas de la lista HIBP Top 1000 ni variaciones obvias del nombre de usuario | Las contraseñas más comunes son el primer objetivo de ataques de credenciales                  |
| **Prohibición de reutilización**       | No reutilizar las últimas 5 contraseñas                                                        | Evita ciclos de contraseñas predecibles                                                         |
| **Vigencia máxima**                     | 180 días (6 meses) para cuentas operativas; 90 días para cuentas de administrador              | Limita la ventana de exposición ante una credencial comprometida no detectada                   |
| **Cambio forzado en primer acceso**      | Sí — toda cuenta nueva requiere cambio de contraseña en el primer login                       | La contraseña inicial asignada por el Administrador no debe usarse más allá del primer acceso |

### 6.2 Almacenamiento de contraseñas

Las contraseñas **nunca se almacenan en texto plano**. SmartCSET utiliza `password_hash()` de PHP con el algoritmo `PASSWORD_BCRYPT` (costo 12 por defecto), que genera un hash con sal aleatoria integrada. Este mecanismo hace computacionalmente inviable la recuperación de la contraseña original a partir del hash almacenado en `tab_usuarios.pass_usuario`.

### 6.3 Transmisión de contraseñas

Las contraseñas se transmiten exclusivamente a través de conexiones HTTPS (TLS). Queda **prohibido**:

- Enviar contraseñas por correo electrónico, mensajes de texto o cualquier canal de comunicación no cifrado.
- Registrar contraseñas en texto plano en logs del sistema, archivos de configuración o comentarios de código.
- Comunicar verbalmente contraseñas en espacios donde puedan ser escuchadas por personas no autorizadas.

### 6.4 Contraseñas de servicios y cuentas técnicas

Las contraseñas de cuentas de servicio (usuario PostgreSQL de la aplicación, usuario `postgres` de administración, credenciales SSH del servidor) se gestionan conforme a reglas más estrictas:

- Se almacenan exclusivamente en el archivo `.env` del servidor, con permisos de sistema operativo restringidos al usuario que ejecuta el servidor web.
- El archivo `.env` no forma parte del repositorio git (figura en `.gitignore`).
- Se registran en un gestor de contraseñas institucional o en un documento custodiado físicamente por el Administrador del sistema.
- Se rotan inmediatamente cuando se sospecha que han sido comprometidas o cuando el personal con conocimiento de ellas se desvincula.

---

## 7. CICLO DE VIDA DE LOS ACCESOS — ALTAS, MODIFICACIONES Y BAJAS

### 7.1 Alta de un nuevo usuario

```
PASO 1 — SOLICITUD FORMAL
   El responsable inmediato del nuevo usuario solicita el acceso al
   Administrador del sistema, especificando: nombre completo, cargo,
   función que desempeñará en SmartCSET y módulos que necesita.
        ↓
PASO 2 — APROBACIÓN
   El Responsable de Seguridad de la Información (o el Administrador,
   si el RSSI no está designado aún) aprueba la solicitud y confirma
   que los módulos requeridos son coherentes con la función declarada.
        ↓
PASO 3 — CREACIÓN DE LA CUENTA
   El Administrador crea la cuenta en SmartCSET con:
   • Identificador único nominal
   • Contraseña temporal que el usuario debe cambiar en el primer login
   • Solo los menús estrictamente necesarios para su función
   • ind_usuario = FALSE (a menos que el rol requiera administración)
        ↓
PASO 4 — ENTREGA Y ACUERDO DE USO
   El usuario recibe sus credenciales iniciales mediante canal seguro
   (entrega presencial o mensaje interno cifrado), firma o acepta el
   Acuerdo de Uso Aceptable y recibe la capacitación mínima de
   seguridad antes de activar el acceso.
        ↓
PASO 5 — REGISTRO
   El alta queda registrada en la bitácora de gestión de accesos
   (fecha, usuario creado, solicitante, módulos asignados, aprobador).
```

### 7.2 Modificación de accesos

Toda modificación de permisos (agregar o quitar módulos, cambiar nivel de privilegio) requiere:

1. Solicitud formal del responsable inmediato del usuario, con justificación del cambio.
2. Aprobación del Responsable de Seguridad de la Información.
3. Implementación por el Administrador.
4. Registro en la bitácora de gestión de accesos.

Queda **prohibido** que el Administrador modifique permisos sin solicitud formal, incluidos los propios permisos del Administrador.

### 7.3 Baja de usuario — proceso de desvinculación

Este es el punto de mayor riesgo en el ciclo de vida de los accesos. La baja de un usuario debe ejecutarse el **mismo día** en que se efectiva su desvinculación del cargo o función que justificaba el acceso.

```
PASO 1 — NOTIFICACIÓN
   El área de gestión humana o el responsable inmediato notifica al
   Administrador del sistema con al menos 1 día de anticipación (o
   de forma inmediata en casos de desvinculación urgente/disciplinaria).
        ↓
PASO 2 — REVOCACIÓN INMEDIATA DE ACCESO LÓGICO
   El Administrador establece ind_estado = FALSE en tab_usuarios para
   la cuenta del usuario que se desvincula. La cuenta queda inactiva
   de inmediato: no puede autenticarse, pero sus registros históricos
   se preservan intactos para trazabilidad.
        ↓
PASO 3 — REVOCACIÓN DE ACCESO FÍSICO
   Se retiran las llaves, tarjetas de acceso o códigos que permitan
   al usuario acceder al cuarto de servidores u otras zonas restringidas.
        ↓
PASO 4 — CAMBIO DE CONTRASEÑAS COMPARTIDAS (si aplica)
   Si el usuario que se desvincula tenía conocimiento de contraseñas
   de servicio o de acceso a infraestructura (PostgreSQL, SSH), estas
   se rotan inmediatamente.
        ↓
PASO 5 — VERIFICACIÓN
   El Administrador confirma que el usuario ya no puede autenticarse
   (prueba de login con las credenciales del usuario dado de baja).
        ↓
PASO 6 — REGISTRO
   La baja queda registrada en la bitácora de gestión de accesos con
   fecha, hora, usuario dado de baja, motivo y responsable de la acción.
```

> ⚠️ **Riesgo crítico del proceso de baja:** La evidencia histórica de incidentes de seguridad a nivel mundial muestra que una de las causas más frecuentes de brechas de datos son los **accesos de exempleados no revocados**. Un usuario desvinculado con acceso activo puede, por acción u omisión, comprometer la confidencialidad o integridad del sistema. La inmediatez de la baja no es una recomendación: es un requisito de esta Política.

### 7.4 Bitácora de gestión de accesos

| N° | Fecha/hora | Tipo (alta/mod/baja) | Usuario afectado | Módulos asignados / modificados / revocados | Solicitante | Aprobador | Ejecutado por | Observaciones |
| --- | ---------- | -------------------- | ---------------- | -------------------------------------------- | ----------- | --------- | ------------- | ------------- |
|     |            |                      |                  |                                              |             |           |               |               |

---

## 8. CONTROL DE ACCESOS PRIVILEGIADOS

Los accesos privilegiados (cuentas de administrador del sistema, acceso directo a la base de datos, acceso SSH al servidor) representan el mayor riesgo de la arquitectura de acceso de SmartCSET, ya que su uso inadecuado puede comprometer la totalidad del sistema.

### 8.1 Reglas para cuentas de administrador de SmartCSET (`ind_usuario = TRUE`)

1. El número de cuentas con perfil de administrador debe minimizarse al máximo necesario para la operación. **En condiciones normales, no debería haber más de 2 cuentas de administrador activas simultáneamente** (una principal y una de respaldo operacional).
2. Las cuentas de administrador **no se usan para las tareas operativas diarias** que no requieren privilegios de administración. Si el Administrador necesita verificar el funcionamiento del sistema como usuario operativo, utiliza una cuenta operativa separada para esa prueba.
3. Toda acción ejecutada con una cuenta de administrador queda registrada en las columnas de auditoría del sistema (`usr_insert`, `fec_insert`, `usr_update`, `fec_update`).
4. La contraseña de las cuentas de administrador se rige por los requisitos más estrictos de la Sección 6.1 (vigencia de 90 días, complejidad obligatoria) y se cambia inmediatamente ante cualquier sospecha de compromiso.

### 8.2 Reglas para el acceso directo a la base de datos PostgreSQL

El acceso directo a la base de datos (con `psql` o cualquier cliente de BD) está reservado exclusivamente para el Administrador del sistema y el personal autorizado de la Oficina de TI, bajo las siguientes condiciones:

1. **Solo para tareas que no pueden realizarse desde la aplicación**: migraciones, despliegue de funciones PL/pgSQL, backups, diagnósticos.
2. **Nunca para consultar o exportar datos personales de manera masiva** fuera de los procedimientos de backup y auditoría formales.
3. **Toda sesión de acceso directo a la BD debe documentarse**: fecha, hora, persona, propósito y acciones realizadas.
4. El usuario `postgres` (superusuario de PostgreSQL) se usa **solo** para tareas de administración del motor de BD (instalación, configuración, creación de roles). La aplicación PHP **nunca** conecta con el usuario `postgres`.

### 8.3 Reglas para el acceso SSH al servidor

1. El acceso SSH se permite **exclusivamente mediante autenticación por clave pública** (par de claves RSA o ED25519). La autenticación por contraseña está deshabilitada en el servidor (`PasswordAuthentication no` en `sshd_config`).
2. Las claves privadas SSH se almacenan en los equipos personales autorizados del Administrador, protegidas con passphrase.
3. Se mantiene un registro de qué claves públicas están autorizadas (`~/.ssh/authorized_keys`) y se revisan y depuran en cada auditoría trimestral.
4. El acceso SSH desde redes externas a la red del SENA requiere justificación previa y se realiza a través de la VPN institucional cuando esta esté disponible.

---

## 9. CONTROL DE ACCESO REMOTO

### 9.1 Acceso remoto a la aplicación

SmartCSET es una aplicación web. El acceso remoto por parte de usuarios operativos (personal de portería desde otro equipo en la red del Centro) se realiza a través del navegador web mediante HTTPS. No se requiere ninguna configuración adicional de acceso remoto para el uso normal de la aplicación.

### 9.2 Acceso remoto para administración técnica

El acceso remoto para administración técnica del servidor (SSH, acceso a la BD) se permite bajo las siguientes condiciones:

| Condición     | Requerimiento                                                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Autenticación | Exclusivamente por clave pública SSH (nunca por contraseña)                                                                              |
| Red de origen  | Preferiblemente desde la red interna del SENA; desde redes externas, solo con VPN institucional o con registro previo de la IP de origen   |
| Registro       | Toda sesión de administración remota queda registrada en el log del sistema operativo del servidor (`/var/log/auth.log` o equivalente) |
| Propósito     | Declarado antes de cada sesión; documentado en la bitácora de accesos privilegiados                                                      |

### 9.3 Prohibiciones de acceso remoto

- Queda **prohibido** acceder a SmartCSET desde redes WiFi públicas no seguras sin uso de VPN.
- Queda **prohibido** utilizar herramientas de escritorio remoto (TeamViewer, AnyDesk, RDP) para acceder al servidor de SmartCSET, salvo en situaciones de emergencia documentadas y aprobadas por el RSSI.
- Queda **prohibido** el acceso remoto a la base de datos PostgreSQL desde fuera de la red del SENA: el puerto 5432 debe estar bloqueado para conexiones externas en el firewall perimetral.

---

## 10. CONTROL DE ACCESO FÍSICO

### 10.1 Zonas de acceso restringido

| Zona                                                      | Descripción                                                                      | Nivel de restricción                                                            |
| --------------------------------------------------------- | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Cuarto de servidores**                            | Espacio donde residen los servidores que alojan SmartCSET y su base de datos      | Máximo — solo personal técnico autorizado con función activa que lo requiera |
| **Sala de equipos de red**                          | Switches, routers, patch panels de la infraestructura del Centro                  | Alto — solo personal de TI autorizado                                           |
| **Puestos de portería**                            | Equipos terminales desde los que opera SmartCSET en el punto de control de acceso | Medio — solo personal de portería en turno activo                              |
| **Oficinas administrativas con acceso a SmartCSET** | Equipos desde los que personal administrativo usa módulos del sistema            | Medio — acceso normal de personal del Centro durante horario laboral            |

### 10.2 Controles de acceso físico al cuarto de servidores

1. **Acceso mediante llave física o control electrónico**: solo el Administrador del sistema y el personal autorizado de la Oficina de TI tienen llave o código de acceso al cuarto de servidores. El número de personas con acceso debe minimizarse.
2. **Registro de visitas**: toda persona que acceda al cuarto de servidores, incluyendo el Administrador, registra su ingreso y salida en la bitácora física del cuarto (nombre, fecha, hora de entrada, hora de salida, motivo).
3. **Prohibición de acceso a visitantes no autorizados**: ninguna persona ajena al Centro de Formación (proveedores, visitantes, aprendices) puede ingresar al cuarto de servidores sin acompañamiento del Administrador o personal autorizado de TI, y solo por el tiempo estrictamente necesario para la tarea que justifica el acceso.
4. **Control de medios físicos**: los medios de almacenamiento (discos externos, USB) que contengan copias de seguridad de SmartCSET se almacenan bajo llave, en el cuarto de servidores o en un lugar de custodia segura designado por la Dirección. No se llevan a domicilios particulares ni se dejan en lugares de acceso libre.

### 10.3 Protección de los servidores contra amenazas físicas y ambientales

| Amenaza                      | Control recomendado                                                                                                          | Estado a verificar                         |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| Corte de energía eléctrica | UPS (Sistema de Alimentación Ininterrumpida) con autonomía mínima de 30 minutos para un apagado controlado                | 🔲 Verificar con Oficina TI                |
| Incendio / inundación       | El cuarto de servidores no debe ubicarse en sótanos ni cerca de tuberías; extinguidor apropiado para equipos electrónicos | 🔲 Verificar condiciones físicas actuales |
| Temperaturas extremas        | Sistema de climatización dedicado o ventilación adecuada para mantener temperatura operativa de los equipos                | 🔲 Verificar con Oficina TI                |
| Robo de equipos              | Servidores atornillados o anclados al rack; rack con cerradura; CCTV en el cuarto o en el acceso al mismo                    | 🔲 Verificar con Oficina TI                |

### 10.4 Política de escritorio limpio y pantalla limpia

Todo el personal que opera SmartCSET cumple las siguientes reglas en su puesto de trabajo:

1. **Escritorio limpio**: al finalizar la jornada o al ausentarse del puesto, no se dejan documentos con información del sistema (listados de personas, reportes impresos con datos personales, anotaciones con contraseñas) a la vista o al alcance de personas no autorizadas.
2. **Pantalla limpia**: al ausentarse del puesto de trabajo por más de 5 minutos, el usuario bloquea la pantalla de su equipo o cierra la sesión de SmartCSET. Los equipos de portería tienen configurado el bloqueo automático de pantalla a los 5 minutos de inactividad.
3. **Cierre de sesión**: al finalizar el turno o la jornada, el usuario cierra explícitamente su sesión en SmartCSET mediante la opción de cierre de sesión del sistema (nunca simplemente cerrando el navegador sin cerrar sesión).
4. **Documentos impresos con datos personales**: los reportes impresos que contengan datos personales de personas registradas en el sistema deben destruirse mediante trituración cuando ya no sean necesarios. No se desechan en la papelera común.

---

## 11. SEGURIDAD DEL PUESTO DE TRABAJO Y EQUIPOS

### 11.1 Equipos autorizados para acceder a SmartCSET

SmartCSET solo es accesible desde **equipos institucionales del SENA** debidamente configurados y supervisados por la Oficina de TI. El uso de dispositivos personales (BYOD — *Bring Your Own Device*) para acceder al sistema está **prohibido**, salvo autorización expresa y documentada de la Dirección del Centro y bajo condiciones técnicas de seguridad equivalentes a los equipos institucionales.

### 11.2 Configuración mínima de seguridad de los equipos terminales

| Requisito                                 | Descripción                                                                                                                                                                           |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sistema operativo actualizado**   | El equipo debe tener aplicadas las actualizaciones de seguridad del sistema operativo vigentes                                                                                         |
| **Antivirus activo**                | Software antivirus/antimalware activo y con definiciones actualizadas                                                                                                                  |
| **Bloqueo automático de pantalla** | Configurado a los 5 minutos de inactividad como máximo                                                                                                                                |
| **Navegador actualizado**           | Se usa un navegador web moderno con soporte activo de seguridad (Chrome, Firefox, Edge en versión actual)                                                                             |
| **Sin software no autorizado**      | Los equipos de portería y registro solo tienen instalado el software necesario para su función; no se instala software de entretenimiento, juegos ni aplicaciones no institucionales |

### 11.3 Mantenimiento y disposición final de equipos

- Los equipos que dejan de usarse para operar SmartCSET deben tener sus discos duros borrados de forma segura (sobreescritura o destrucción física del medio) antes de ser reasignados, donados o desechados.
- La Oficina de TI del SENA es responsable de garantizar el borrado seguro de la información en los equipos que salen del inventario institucional.

---

## 12. REVISIÓN PERIÓDICA DE ACCESOS

Conforme al Cronograma de Auditorías (FASE0-AUD-005), los accesos al sistema se revisan de forma regular para detectar y corregir desviaciones respecto al principio de mínimo privilegio:

| Tipo de revisión                             | Periodicidad | Qué se verifica                                                                                                                                                    | Responsable                            |
| --------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| **Revisión de usuarios activos**       | Trimestral   | Lista completa de usuarios con `ind_estado = TRUE`; confirmar que cada usuario activo sigue teniendo función que justifica el acceso                             | Administrador del sistema              |
| **Revisión de menús asignados**       | Trimestral   | Para cada usuario activo, verificar que los menús asignados son coherentes con su función actual (puede haber cambiado de cargo)                                  | Administrador del sistema              |
| **Revisión de cuentas privilegiadas**  | Trimestral   | Confirmar que el número de cuentas con `ind_usuario = TRUE` es el mínimo necesario; verificar que no existen cuentas de administrador de personas desvinculadas | RSSI                                   |
| **Revisión de acceso físico**         | Semestral    | Verificar que la lista de personas con acceso al cuarto de servidores (llaves, códigos) coincide con el personal activo con función que lo requiere               | Administrador del sistema + Oficina TI |
| **Revisión de claves SSH autorizadas** | Trimestral   | Verificar el archivo `authorized_keys` del servidor; eliminar claves de personal desvinculado                                                                     | Administrador del sistema              |
| **Revisión de usuarios de BD**         | Semestral    | Verificar los roles y permisos de todos los usuarios de PostgreSQL; confirmar que el usuario de la aplicación no tiene privilegios DDL                             | Administrador del sistema              |

---

## 13. REGISTRO Y AUDITORÍA DE ACCESOS

### 13.1 Eventos que se registran obligatoriamente

> ⚠️ Esta tabla define la **obligación de registro objetivo** del sistema. La columna "Estado" indica qué registros operan hoy y cuáles entran en operación con la Fase 1 del Plan de Blindaje (FASE1-BLI-001) o dependen de configuración de infraestructura a coordinar con la Oficina TI SENA.

| Evento                                 | Dónde se registra                                            | Tiempo de retención del registro | Estado |
| -------------------------------------- | ------------------------------------------------------------- | --------------------------------- | ------ |
| Inicio de sesión exitoso              | `tab_sesiones` (con IP de origen, vía `accesoIngresoSesion()`) | Mínimo 90 días                  | ✅ Implementado |
| Intento de autenticación exitoso      | `tab_intentos_login` (exitoso = TRUE) + columnas de sesión | Mínimo 90 días                  | 🔲 Fase 1 E3 |
| Intento de autenticación fallido      | `tab_intentos_login` (exitoso = FALSE)                      | Mínimo 90 días                  | 🔲 Fase 1 E3 |
| Bloqueo de IP por rate limiting        | Log del servidor /`tab_intentos_login`                      | Mínimo 90 días                  | 🔲 Fase 1 E3 |
| Alta, modificación y baja de usuarios | Bitácora de gestión de accesos (Sección 7.4) + columnas de auditoría `usr_insert`/`usr_update` | Mientras dure el sistema          | ✅ Columnas de auditoría / 🔲 bitácora formal |
| Acceso directo a la base de datos      | Log del servidor PostgreSQL (`pg_log`)                      | Mínimo 180 días                 | 🔲 Verificar configuración con Oficina TI |
| Acceso SSH al servidor                 | `/var/log/auth.log` del sistema operativo                   | Mínimo 180 días                 | 🔲 Verificar configuración con Oficina TI |
| Acceso físico al cuarto de servidores | Bitácora física del cuarto                                  | Mínimo 1 año                    | 🔲 Implantar con Oficina TI |

### 13.2 Protección de los registros de acceso

Los registros de auditoría de accesos no pueden ser modificados ni eliminados por los usuarios cuyas acciones registran. El Administrador del sistema tiene acceso de lectura a los registros, pero las modificaciones o eliminaciones requieren aprobación del RSSI y quedan a su vez registradas. Esta protección preserva la integridad de la evidencia de auditoría.

---

## 14. AUTENTICACIÓN MULTIFACTOR — HOJA DE RUTA

La autenticación multifactor (MFA) —que exige al usuario demostrar su identidad mediante dos o más factores independientes (algo que sabe, algo que tiene, algo que es)— representa el control de acceso de mayor impacto para reducir el riesgo de cuentas comprometidas.

### 14.1 Estado actual

SmartCSET opera con autenticación de **un solo factor** (usuario + contraseña). Los controles compensatorios vigentes hoy son: contraseñas hasheadas con bcrypt, registro de sesiones con validación de IP de origen (`tab_sesiones`) y acceso restringido a la red institucional. Los controles compensatorios adicionales planificados —rate limiting y logging de intentos fallidos (🔲 Fase 1 E3, FASE1-BLI-001) y auditorías trimestrales de accesos (🔲 primer ciclo según FASE0-AUD-005)— deben implementarse antes de considerar plenamente compensada la ausencia de MFA. Mientras tanto, el riesgo de fuerza bruta contra el formulario de login permanece abierto y está identificado en la Matriz de Riesgos (R-A01, FASE0-RIE-003).

### 14.2 Hoja de ruta de implementación de MFA

| Fase                    | Acción                                                                                                                                                                                          | Cuándo                                         |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------- |
| **Corto plazo**   | Implementar MFA para las cuentas de administrador (`ind_usuario = TRUE`) mediante TOTP (Google Authenticator, Authy, o librería PHP TOTP) — son las cuentas de mayor impacto ante una brecha | Al implementarse la Fase 2 del Plan de Blindaje |
| **Mediano plazo** | Extender MFA a todos los usuarios del sistema, con prioridad en los que tienen acceso a módulos de gestión de datos de personas                                                                | Durante la Fase 3 del Plan de Blindaje          |
| **Largo plazo**   | Evaluar integración con el sistema de identidad institucional del SENA (si existe directorio activo o SSO corporativo)                                                                          | Fase 5 — Mejora continua                       |

---

## 15. RESPONSABILIDADES

| Rol                                                          | Responsabilidades en control de acceso                                                                                                                                                                                        |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Dirección del Centro de Formación**                | Aprobar esta Política; garantizar que la estructura física (cuarto de servidores, controles de acceso físico) cumpla los requisitos aquí definidos; designar al Administrador del sistema y al RSSI                       |
| **Responsable de Seguridad de la Información (RSSI)** | Supervisar el cumplimiento de esta Política; aprobar altas, modificaciones y bajas de accesos privilegiados; revisar trimestralmente la lista de cuentas activas y sus permisos                                              |
| **Administrador del sistema**                          | Implementar y mantener los controles de acceso lógico; gestionar el ciclo de vida de los usuarios; ejecutar las revisiones periódicas de accesos; documentar en la bitácora; aplicar el proceso de baja de forma inmediata |
| **Oficina de TI del SENA**                             | Gestionar los controles de acceso físico al cuarto de servidores; garantizar la seguridad ambiental (UPS, climatización, CCTV); gestionar el acceso SSH y las credenciales de infraestructura                               |
| **Responsables inmediatos del personal**               | Notificar al Administrador y al RSSI de forma inmediata ante cualquier cambio de función o desvinculación de su personal con acceso al sistema                                                                              |
| **Todo el personal con acceso**                        | Custodiar sus credenciales; no compartirlas; reportar de inmediato cualquier sospecha de compromiso de su cuenta; cumplir las normas de escritorio limpio y cierre de sesión                                                 |

---

## 16. VIGENCIA, REVISIÓN Y ACTUALIZACIÓN

1. Esta Política entra en vigencia a partir de su aprobación formal por la Dirección del Centro de Formación.
2. Se revisa **anualmente** en el marco de la auditoría anual definida en el Cronograma de Auditorías (FASE0-AUD-005), o de forma extraordinaria ante:
   - Cambio en la planta de personal con acceso al sistema.
   - Cambio en la arquitectura técnica o en los módulos de SmartCSET.
   - Incidente de seguridad relacionado con accesos no autorizados.
   - Cambio normativo relevante en el MSPI o en la normativa colombiana de seguridad digital.
3. Se mantiene un histórico de versiones del documento con indicación de los cambios realizados y su motivo.

---

## 17. APROBACIÓN INSTITUCIONAL

|                  | ELABORÓ | REVISÓ | APROBÓ |
| ---------------- | -------- | ------- | ------- |
| **Nombre** |          |         |         |
| **Cargo**  |          |         |         |
| **Fecha**  |          |         |         |
| **Firma**  |          |         |         |

🔲 *Pendiente de diligenciamiento por las instancias institucionales competentes: Administrador del sistema (elaboró), Responsable de Seguridad de la Información (revisó) y Dirección del Centro de Formación (aprobó).*

---

*Fin del documento — Política de Control de Acceso y Seguridad Física — SmartCSET v1.0*
