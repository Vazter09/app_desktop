# Explicación: porqués del diseño as-built

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6, 7, 8

**Audiencia:** Desarrolladores, revisores, TI técnico  
**Tipo:** Explicación Diátaxis

---

## Propósito

Este documento responde **por qué** la app de escritorio está construida como está hoy (as-built), no cómo usarla paso a paso. Para operación diaria ver el [tutorial](tutorial-primer-uso.md) y las [guías](guias/).

---

## 1. ¿Por qué sesión web (PHP) y no un token de dispositivo?

La app usa el **mismo login** que la web: usuario, contraseña y cookie `PHPSESSID`.

**Motivos:**

- Un solo modelo de identidad y auditoría: `usr_insert` queda con el usuario real (ej. `porteria`), no un “dispositivo anónimo”.
- Reutiliza rate limiting (E3), hardening de sesión (E4) y control de menú de portería en el servidor (E1).
- Evita un canal de autenticación paralelo que habría que blindar y auditar por separado.

La cookie vive en memoria (`CookieJar`); no se escribe en disco en texto plano. Al cerrar con **Salir**, se hace logout en el servidor.

---

## 2. ¿Por qué el motor biométrico es in-process?

El diseño original (`REGLAS_APP_ESCRITORIO_SGI.md`) contemplaba un **segundo proceso** con API HTTPS en loopback para el motor facial.

**As-built:** YuNet + SFace corren **dentro del mismo proceso** Python que la UI Tkinter.

**Motivos prácticos:**

- OpenCV ya está cargado para la cámara; un segundo proceso duplicaría memoria y complejidad de empaquetado.
- El motor no queda expuesto en un puerto local (superficie de ataque menor en el PC).
- El vector (128 floats) se calcula en RAM y se envía por HTTPS al backend; no se persiste en disco del cliente.

El motor en dos procesos HTTPS queda como deuda / Fase 2 documentada, no como comportamiento actual.

---

## 3. ¿Por qué no hay sidebar?

Tras el login, el shell muestra **solo** la pantalla unificada de reconocimiento + formulario (cámara | formulario | huella ilustrativa).

**Motivos:**

- El puesto de portería prioriza **velocidad y un solo flujo** (identificar / capturar / registrar).
- Menos navegación = menos error operativo bajo presión de fila.
- Existen páginas en código (`inicio`, `salida`, `entradas`) pero **sin** entrada de menú visible: código huérfano de UI, no producto expuesto al operario.

Si en el futuro se necesitan KPIs o CRUD de entradas en desktop, habría que añadir navegación explícita en `AppShell` — hoy eso se hace por la **web** cuando aplica.

---

## 4. ¿Por qué confirmación visual antes de registrar?

Tras un match facial aparece `IdentificationConfirmationPanel` con la **foto de enrolamiento del servidor** y los datos de la persona.

**Motivos (E1 + E6 / integridad):**

- Reduce el impacto de un falso positivo del umbral coseno.
- Obliga al operario a contrastar identidad física vs registro.
- La foto en vivo **no** sustituye la foto guardada salvo fallback explícito si el servidor no devolvió imagen.

Hay auto-registro tras ~2,5 s si no se cancela: equilibra seguridad y velocidad de fila. **Cancelar** evita cualquier escritura.

---

## 5. Otras decisiones relacionadas

| Decisión | Por qué |
|----------|---------|
| Sin BD local | Una sola fuente de verdad; reglas de ingreso único en PostgreSQL |
| HTTPS obligatorio | Datos biométricos e identidad en tránsito (MSPI Eje 8) |
| `verify_tls` configurable | Lab con cert autofirmado; prod debe ir en `true` |
| Huella solo ilustrativa | Hardware/SDK no integrado; no simular funcionalidad falsa |
| Foto en servidor (Opción A) | No BYTEA en BD; validación MIME (E6) en backend |
| HTTP con `urllib` | Menos dependencia externa; cookie jar stdlib |

---

## Documentos relacionados

- Arquitectura fuente: [`../03-arquitectura.md`](../03-arquitectura.md)
- Seguridad: [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md)
- Roles: [`referencia-roles.md`](referencia-roles.md)
- Despliegue TLS: [`../operacion/despliegue-produccion.md`](../operacion/despliegue-produccion.md)
