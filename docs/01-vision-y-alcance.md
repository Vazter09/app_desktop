# 01 — Visión y alcance

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## 1. Visión

SmartCSET App de Escritorio es un **cliente de portería** para centros de formación del SENA. Permite al personal de control de acceso registrar **ingresos y salidas** de personas (aprendices, instructores, visitantes, etc.) usando **reconocimiento facial**, captura manual de documento o lectura por **pistola de códigos** (QR / barras / PDF417).

La aplicación **no es un sistema independiente**. Es un cliente más del ecosistema SmartCSET — igual que la interfaz web y la app móvil — que se comunica por **HTTPS** con el backend PHP existente y persiste datos en la **misma base PostgreSQL** del sistema.

---

## 2. Problema que resuelve

| Situación actual (web) | Con la app de escritorio |
|------------------------|--------------------------|
| Portería depende del navegador y pestañas abiertas | Aplicación dedicada, pantalla completa, flujo único |
| Ingreso manual lento en horas pico | Identificación facial automática con confirmación visual |
| Sin captura biométrica en el PC de portería | Enrolamiento e identificación con cámara local + vector en pgvector |
| Operario debe alternar entre teclado y lector | Formulario + cámara + pistola en una sola pantalla |

---

## 3. Actores

| Actor | Rol | Interacción |
|-------|-----|-------------|
| **Operario de portería** | Usuario principal | Login, identificar/enrolar rostros, registrar ingreso/salida, captura manual |
| **Administrador del sistema** | Usuario con permisos elevados | CRUD de entradas/puertas (código existe; **no expuesto en UI actual**) |
| **Backend SmartCSET** | Servidor institucional | Autenticación, reglas de negocio, persistencia |
| **TI / instalador** | Despliegue | Configura URL del servidor, genera `.exe`, verifica cámara y red |

---

## 4. Alcance incluido (as-built)

### 4.1 Autenticación

- Login con **usuario y contraseña reales** de SmartCSET (sesión PHP + cookie `PHPSESSID`).
- Mismo mecanismo que la web; **no** usa token de dispositivo móvil.
- Logout al cerrar la aplicación.

### 4.2 Portería unificada (pantalla principal post-login)

Tras autenticarse, la app abre directamente la pantalla de **Sistema de Reconocimiento Multibiométrico** con tres zonas:

| Zona | Función |
|------|---------|
| Izquierda | Vista de cámara en vivo + controles de captura facial |
| Centro | Formulario de ingreso manual / datos de persona |
| Derecha | Área de huella dactilar (UI visual; hardware pendiente) |

### 4.3 Reconocimiento facial

- Detección: **YuNet** (ONNX, opencv_zoo).
- Embedding: **SFace** (128 dimensiones).
- Enrolamiento con foto JPG enviada al servidor.
- Identificación por similitud coseno en `tab_enrolamiento_facial` (pgvector HNSW).
- Confirmación visual antes de registrar (panel embebido con foto del servidor).
- Registro automático con `id_metodo_aut = 4` (biométrico facial).

### 4.4 Captura manual y pistola

- Ingreso por documento con `id_metodo_aut = 1` (manual).
- Lectura QR (`metodo_aut = 2`) o código de barras / PDF417 (`metodo_aut = 3`).
- Parseo local en [`src/ui/scan_capture.py`](../src/ui/scan_capture.py).

### 4.5 Ingreso y salida

- La app decide automáticamente si corresponde **ingreso** o **salida** según consulta al backend (`ingreso/consultar.php` / `salida/consultar.php`).
- Mismas reglas de negocio que la web (ingreso único por día, etc.).

### 4.6 Empaquetado Windows

- Ejecutable onefile: `SmartCSET_Porteria.exe` (PyInstaller).
- Configuración local `app_config.json` junto al `.exe`.

---

## 5. Alcance excluido

| Elemento | Motivo |
|----------|--------|
| Base de datos propia | Todo vive en PostgreSQL del backend SmartCSET |
| Login por token de dispositivo | Decisión explícita: sesión web real |
| Motor biométrico en proceso HTTPS separado | Diseño futuro (Fase 2); hoy corre in-process |
| SDK de huella dactilar real | Placeholder; `motor/huella.py` genera templates sintéticos |
| Cifrado en reposo de fotos (E2) | Diferido institucionalmente |
| Consentimiento biométrico en UI | Pendiente Fase 0 MSPI |
| Caché offline / sincronización | Feature planificada, no implementada |
| Dashboard KPIs navegable | `InicioPage` existe en código pero **sin menú** que la exponga |
| Página de salida dedicada en menú | `SalidaPage` existe pero **no es la ruta principal**; salida se resuelve desde pantalla de ingreso |
| CRUD de entradas en UI | `EntradasPage` existe pero **no registrada** en navegación |
| Módulo de reportes locales | No implementado |

---

## 6. Restricciones técnicas

| Restricción | Detalle |
|-------------|---------|
| Sin frameworks web | Tkinter + ttk (stdlib Python) |
| HTTP sin `requests` | `urllib` + `http.cookiejar` |
| Mínimas dependencias | Solo opencv, numpy, Pillow, tzdata |
| Intranet SENA | Sin garantía de internet post-instalación |
| Python 3.11+ | Con Tkinter disponible |
| Webcam obligatoria | Para flujo facial |
| HTTPS al backend | Obligatorio; verificación TLS configurable |

---

## 7. Dependencias externas

La app **requiere** que estén operativos en el servidor institucional:

- Backend PHP SmartCSET (Apache + HTTPS).
- PostgreSQL con extensión `vector` (pgvector).
- Endpoints de portería y biometría desplegados.
- Usuario con permiso de menú de portería (ej. `porteria`).

Ver [`07-contrato-integracion.md`](07-contrato-integracion.md) para el inventario completo de endpoints.

---

## 8. Criterios de éxito

| Criterio | Verificación |
|----------|--------------|
| Operario puede iniciar sesión | Login contra `/auth/v1/login.php` |
| Persona enrolada se identifica y registra ingreso | Ciclo facial end-to-end con `metodo_aut=4` |
| Persona con ingreso abierto registra salida | Mismo flujo, decisión automática de modo |
| Sin match facial, operario usa documento manual | Formulario siempre visible (fallback) |
| App no bloquea portería si falla cámara | Captura manual disponible |
| Auditoría registra usuario real | `usr_insert` = usuario de sesión en BD |
| Suite de tests pasa contra backend real | `python -m unittest` en `tests/` |

---

## 9. Glosario

| Término | Definición |
|---------|------------|
| **SGI** | Sistema de Gestión de Ingresos (módulo de portería) |
| **Enrolamiento** | Captura y almacenamiento del vector facial de referencia de una persona |
| **Embedding** | Vector numérico de 128 floats que representa un rostro |
| **metodo_aut** | Catálogo de métodos de autenticación (1=manual, 2=QR, 3=barras, 4=facial, 5=huella) |
| **Ingreso abierto** | Registro en `tab_log_ingresos` donde `fec_salida = fec_ingreso` |
| **As-built** | Estado real del software implementado, no el diseño aspiracional |

---

## Documentos relacionados

- Requisitos detallados: [`02-especificacion-requisitos.md`](02-especificacion-requisitos.md)
- Arquitectura: [`03-arquitectura.md`](03-arquitectura.md)
- Manual de usuario: [`06-manual-usuario.md`](06-manual-usuario.md)
