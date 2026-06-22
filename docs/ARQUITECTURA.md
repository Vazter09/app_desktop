# Arquitectura SmartCSET

**Última actualización:** 22 de junio de 2026  
**Estado:** Objetivo de reorganización (en transición desde `src/`)

---

## Resumen

SmartCSET es un **monolito modular en capas**, con entrada por **routers HTTP**, **servicios de aplicación** compartidos y **reglas de negocio críticas en PostgreSQL** (funciones PL/pgSQL).

No es MVC clásico ni microservicios. Es la evolución natural del PHP procedural actual hacia capas con responsabilidades claras, sin introducir framework ni Composer.

**Nombre técnico:**

> *Layered modular monolith with HTTP routers, shared application services, and database-centric business rules.*

**En español:**

> Monolito modular en capas, basado en routers HTTP, con servicios de aplicación compartidos y reglas de negocio en base de datos.

---

## Principios

1. **Un solo deploy** — Un repositorio, un servidor PHP, una base PostgreSQL.
2. **Routers delgados** — Solo HTTP: auth, método, payload, respuesta. Sin lógica de negocio.
3. **Servicios compartidos** — Web, AJAX y móvil llaman los mismos servicios.
4. **Dominio en BD** — Integridad y reglas críticas en `fun_*()` PL/pgSQL.
5. **Clientes múltiples** — Web (formularios + fetch) y app móvil (JSON).
6. **Sin framework** — `require_once`, prepared statements, vanilla JS.

---

## Estructura del repositorio

```
smartcset/
│
├── frontend/                    # Presentación (navegador)
│   ├── web/
│   │   ├── public/              # Document root del servidor web
│   │   │   ├── index.php        # Login
│   │   │   ├── css/
│   │   │   ├── js/
│   │   │   ├── img/
│   │   │   └── uploads/
│   │   ├── pages/               # Vistas PHP (solo HTML + datos para render)
│   │   │   ├── menu/
│   │   │   ├── usuarios/
│   │   │   ├── admin/
│   │   │   └── modulos/
│   │   │       ├── porteria/
│   │   │       ├── registro/
│   │   │       └── entradas/
│   │   └── layout/              # head, sidebar, topbar, footer
│   │
│   └── services/                # Clientes HTTP del frontend (fetch)
│       ├── http-client.js
│       ├── porteria-router.js
│       └── usuarios-router.js
│
├── backend/                     # Servidor PHP (sin HTML de negocio)
│   ├── routers/                 # Entrada HTTP
│   │   ├── web/                 # Form POST → redirect + flash
│   │   │   └── porteria/
│   │   │       ├── ingreso/registrar.php
│   │   │       └── salida/registrar.php
│   │   │
│   │   └── json/                # fetch / app móvil → JSON
│   │       ├── porteria/v1/
│   │       │   ├── ingreso/registrar.php
│   │       │   ├── ingreso/consultar.php
│   │       │   └── salida/registrar.php
│   │       └── auth/
│   │
│   ├── services/                # Orquestación (sin HTTP)
│   │   ├── porteria/
│   │   │   ├── ingreso_service.php
│   │   │   └── salida_service.php
│   │   ├── usuarios/
│   │   ├── menus/
│   │   └── config/
│   │
│   └── core/                    # Infraestructura
│       ├── bootstrap.php        # Conexión PDO, statements, sesión
│       ├── config.php
│       ├── Db.php
│       ├── AppConfig.php
│       ├── ErrorHandler.php
│       └── SecurityMiddleware.php
│
├── database/                    # PostgreSQL (fuente de verdad del dominio)
│   ├── schema/
│   ├── functions/               # fun_* PL/pgSQL
│   ├── migrations/
│   └── seeds/
│
├── mobile/                      # Clientes nativos
│   └── porteria-app/
│       └── src/
│           ├── routers/         # client.ts — llamadas HTTP al backend
│           ├── screens/
│           └── sync/
│
├── scripts/                     # Dev, deploy, setup (no producción)
│   ├── dev/
│   ├── deploy/
│   └── db/
│
├── storage/                     # Logs, fotos portería, archivos en disco
├── docs/
├── .env
└── README.md
```

---

## Flujo de capas

```
┌──────────────────────────────────────────────────────────────┐
│  PRESENTACIÓN                                                │
│  frontend/web/pages  ·  mobile/screens                        │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│  CLIENTES HTTP                                               │
│  frontend/services/*.js  ·  mobile/src/routers/client.ts     │
└────────────────────────────┬─────────────────────────────────┘
                             │ HTTP
┌────────────────────────────▼─────────────────────────────────┐
│  ROUTERS                                                     │
│  backend/routers/web/  ·  backend/routers/json/              │
│  (auth, método, body, formato de respuesta)                  │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│  SERVICIOS DE APLICACIÓN                                     │
│  backend/services/{modulo}/                                  │
│  (validación ligera, orquestación, mapeo de datos)           │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│  ACCESO A DATOS                                              │
│  Prepared statements ($stmt_*) → fun_*() PL/pgSQL             │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│  PERSISTENCIA                                                │
│  PostgreSQL (tab_*)                                          │
└──────────────────────────────────────────────────────────────┘
```

---

## Responsabilidad por capa

| Capa | Ubicación | Hace | No hace |
|------|-----------|------|---------|
| **Vistas** | `frontend/web/pages/` | HTML, listar datos para render | SQL, reglas de negocio |
| **Clientes FE** | `frontend/services/` | `fetch`, headers, parseo JSON | DOM, lógica de dominio |
| **Routers web** | `backend/routers/web/` | POST formulario → service → redirect + flash | Queries directas |
| **Routers JSON** | `backend/routers/json/` | POST/GET JSON → service → `{ ok, data }` | HTML |
| **Servicios** | `backend/services/` | Orquestar llamadas a `fun_*()` | `echo`, headers HTTP |
| **Core** | `backend/core/` | PDO, config, sesión, statements globales | Lógica de módulos |
| **Funciones BD** | `database/functions/` | Reglas de negocio, integridad, auditoría | Presentación |
| **Móvil** | `mobile/` | UI, offline, sync local | Duplicar reglas de negocio |

---

## Routers: web vs JSON

Ambos tipos son **routers HTTP**. La diferencia es el contrato de respuesta, no la lógica interna.

| Tipo | Carpeta | Entrada | Salida | Uso |
|------|---------|---------|--------|-----|
| **Web** | `backend/routers/web/` | `application/x-www-form-urlencoded` | Redirect + `$_SESSION['flash_*']` | Formularios tradicionales |
| **JSON** | `backend/routers/json/` | `application/json` | `{ "ok": true, "data": {...} }` | AJAX, app móvil |

Un **mismo servicio** puede ser invocado desde ambos routers:

```php
// backend/services/porteria/ingreso_service.php
function ingresoRegistrar(array $datos, string $usrAudit): int
{
    global $stmt_fun_registrar_ingreso, $stmt_buscar_ingreso_abierto;
    return ingresoRegistrarManual(
        $stmt_fun_registrar_ingreso,
        $stmt_buscar_ingreso_abierto,
        $datos,
        $usrAudit
    );
}
```

```php
// backend/routers/json/porteria/v1/ingreso/registrar.php
$id = ingresoRegistrar($datos, $usrAudit);
RouterResponse::json(true, ['id_ingreso' => $id]);
```

```php
// backend/routers/web/porteria/ingreso/registrar.php
$id = ingresoRegistrar($datos, $usrAudit);
$_SESSION['flash_msg'] = 'Ingreso registrado correctamente.';
$_SESSION['flash_tipo'] = 'success';
header('Location: /pages/modulos/porteria/ingreso/');
exit;
```

---

## Convenciones de nombres

### Routers

- Archivos: `{accion}.php` — `registrar.php`, `consultar.php`, `listar.php`
- JSON versionado: `backend/routers/json/{modulo}/v1/`
- Un archivo = un endpoint HTTP (patrón page controller)

### Servicios

- Archivos: `{entidad}_service.php` — `ingreso_service.php`
- Funciones: verbo + entidad — `ingresoRegistrar()`, `salidaConsultar()`
- Sin dependencias HTTP (`$_POST`, `header()`, `echo`)

### Base de datos

- Tablas: `tab_{nombre}`
- Funciones: `fun_{verbo}_{objeto}`
- Migraciones: nombre descriptivo en `database/migrations/`

### Frontend

- Clientes HTTP: `{modulo}-router.js` — `porteria-router.js`
- Vistas: `index.php` (GET), sin procesar POST (eso va al router)

---

## Autenticación por tipo de cliente

| Cliente | Mecanismo | Validado en |
|---------|-----------|-------------|
| Web admin / portería | Sesión PHP (`$_SESSION['id_usuario']`) | Routers web y JSON internos |
| App móvil portería | Token de dispositivo (`Authorization: Bearer`) | Routers JSON `/porteria/v1/` |
| Módulo registro standalone | Sesión propia (`$_SESSION['registro_authenticated']`) | Routers del módulo registro |

---

## Servidor de desarrollo

El document root debe apuntar solo a assets públicos y puntos de entrada expuestos:

```bash
php -S localhost:8080 -t frontend/web/public
```

Los routers del backend se exponen vía rewrite del servidor web o rutas simbólicas configuradas en Apache/Nginx. Ver `scripts/dev/start_dev.sh` cuando esté migrado.

---

## Mapeo desde la estructura actual

Estado legacy en `src/` (junio 2026). Destino tras la reorganización:

| Ubicación actual | Destino |
|------------------|---------|
| `src/core/` | `backend/core/` |
| `src/api/porteria/` | `backend/routers/json/porteria/v1/` |
| `src/modulos/*/procesar.php` | `backend/routers/web/{modulo}/` |
| `src/modulos/*/consultar.php` | `backend/routers/json/{modulo}/v1/` |
| `src/modulos/*/lib/` | `backend/services/{modulo}/` |
| `src/modulos/*/index.php` | `frontend/web/pages/modulos/` |
| `src/layout/` | `frontend/web/layout/` |
| `src/menu/`, `src/usuarios/`, `src/admin/` | `frontend/web/pages/` |
| `css/`, `js/`, `img/` | `frontend/web/public/` |
| `index.php` (raíz) | `frontend/web/public/index.php` |
| `database/` | `database/` (sin cambios) |
| `mobile/porteria-app/` | `mobile/porteria-app/` |
| `tools/` | `scripts/` |

### Punto crítico: menús en BD

`tab_menus.nom_programa` almacena rutas físicas a archivos PHP (ej. `src/modulos/porteria/ingreso/index.php`). Al mover vistas a `frontend/web/pages/`, se requiere:

1. Migración SQL que actualice `nom_programa`, o
2. Capa de compatibilidad temporal (redirects desde rutas legacy).

---

## Plan de migración

| Fase | Acción | Riesgo |
|------|--------|--------|
| **0** | Crear carpetas objetivo; documentar (este archivo) | Ninguno |
| **1** | Unificar `tools/` → `scripts/` | Bajo |
| **2** | Mover `src/core/` y `src/api/` → `backend/core/`, `backend/routers/json/` | Medio |
| **3** | Extraer `src/modulos/*/lib/` → `backend/services/` | Medio |
| **4** | Mover vistas y assets → `frontend/web/` | Alto (menús BD) |
| **5** | Web consume routers JSON vía `frontend/services/` | Medio |
| **6** | Eliminar `procesar.php` legacy cuando cada módulo esté migrado | Bajo |

Migrar **un módulo a la vez**. Portería es el candidato natural: la app móvil ya usa routers JSON en `src/api/porteria/`.

---

## Qué NO es esta arquitectura

| Patrón | Por qué no aplica |
|--------|-------------------|
| **MVC** | No hay Model/View/Controller como capas de framework |
| **Microservicios** | Un solo proceso PHP, una BD |
| **API REST como capa separada** | Los routers JSON son un tipo de router, no una "API" aparte del backend |
| **Hexagonal / Clean pura** | El dominio vive repartido entre servicios PHP y funciones PL/pgSQL |
| **SPA obligatorio** | La web puede seguir con vistas PHP; los routers JSON son opcionales por módulo |

---

## Relación con otros documentos

| Documento | Contenido relacionado |
|-----------|----------------------|
| [CLAUDE.md](../CLAUDE.md) | Convenciones generales del proyecto (estado legacy) |
| [AGENTS.md](../AGENTS.md) | Contratos entre subsistemas para agentes IA |
| [database.md](database.md) | Instalación y migraciones PostgreSQL |
| [database-functions.md](database-functions.md) | Funciones `fun_*` de portería |
| [modulos.md](modulos.md) | Estructura actual de `src/modulos/` |
| [ARQUITECTURA_ERRORES.md](ARQUITECTURA_ERRORES.md) | Capa transversal de manejo de errores |

---

## Reglas para contribuir

1. **Nueva funcionalidad** → servicio en `backend/services/` + función PL/pgSQL si hay regla de negocio.
2. **Nuevo endpoint** → router en `backend/routers/web/` o `backend/routers/json/`, nunca lógica suelta en la vista.
3. **Vista PHP** → solo consultas de lectura para render; escritura vía router.
4. **JavaScript** → llamadas HTTP solo desde `frontend/services/`, no `fetch` disperso en vistas.
5. **Móvil** → mismos servicios backend que la web; sin SQL en la app.
6. **Deploy de funciones** → actualizar `database/functions/` y `scripts/db/setup_smartcset.sh`.
