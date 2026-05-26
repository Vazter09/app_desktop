# 🏗️ ARQUITECTURA - Sistema de Manejo de Errores

```
┌────────────────────────────────────────────────────────────────────────┐
│                         NAVEGADOR DEL USUARIO                          │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    INTERFAZ (menu_usuarios.php)                  │  │
│  │                         (HTML + Bootstrap)                        │  │
│  │                                                                   │  │
│  │  [Usuario ▼] [Menú 1 ☑] [Menú 2 ☐] ... [Guardar]              │  │
│  └──────────────────┬───────────────────┬──────────────────────────┘  │
│                     │                   │                               │
│                     ▼                   ▼                               │
│          ┌─────────────────┐   ┌─────────────────┐                    │
│          │ CARGAR MENÚS    │   │ GUARDAR MENÚS   │                    │
│          │    (AJAX GET)   │   │    (AJAX POST)  │                    │
│          └────────┬────────┘   └────────┬────────┘                    │
│                   │                     │                               │
│                   │ fetch()             │ fetch()                       │
│                   │                     │                               │
└───────────────────┼─────────────────────┼───────────────────────────────┘
                    │                     │
                    │                     │
        ┌───────────▼────────────────────▼──────────┐
        │         JAVASCRIPT (NAVEGADOR)            │
        │      js/menu_usuarios.js (~280 líneas)   │
        │                                            │
        │  • limpiarFormulario()                    │
        │  • cargarMenusAsignados()                 │
        │  • mostrarErrorCategorizado() ← NUEVO    │
        │  • mostrarExito() ← NUEVO                │
        │  • Event listeners                        │
        └────────┬──────────────────┬───────────────┘
                 │                  │
                 │ solicitud HTTP   │ solicitud HTTP
                 │ GET + parámetros │ POST + datos
                 │                  │
        ┌────────▼──────────────────▼──────────────────────────────────┐
        │                        APACHE/PHP                             │
        │                                                                │
        │  ┌────────────────────────────────────────────────────────┐  │
        │  │        obtener_menus_usuario.php (GET)                │  │
        │  │                                                         │  │
        │  │  1. Validar parámetro                                  │  │
        │  │     ErrorHandler::validateNotEmpty()                  │  │
        │  │                           │                            │  │
        │  │  2. Consultar BD          ▼─── VALIDACIÓN OK ───►    │  │
        │  │     SELECT menús          VALIDACIÓN ERROR           │  │
        │  │                           ├─ Throw Exception         │  │
        │  │  3. Retornar JSON         └─ Catch handleValidation  │  │
        │  │     {status, source}                                  │  │
        │  └────────────────────────────────────────────────────────┘  │
        │                              ▲                                 │
        │  ┌────────────────────────┐   │                              │
        │  │   procesar_perfil.php  │   │ Respuesta JSON              │
        │  │      (POST)            │   │ {status,                    │
        │  │                        │   │  source,                    │
        │  │  1. Validar usuario    │   │  message,                   │
        │  │  2. BEGIN TRANSACTION  │   │  sqlstate,                  │
        │  │  3. DELETE menús viejos│   │  debug}                     │
        │  │  4. INSERT menús nuevos│   │                             │
        │  │  5. Si error:          │   │                             │
        │  │     → ROLLBACK         │   │                             │
        │  │     → PDOException     │   │                             │
        │  │     → handleDatabase...│───┘                             │
        │  │  6. Si ok: COMMIT      │                                │
        │  │     → Respuesta OK     │                                │
        │  └────────────────────────┘                                │
        │                ▲                                             │
        │                │                                             │
        │         ┌──────┴──────────────────────────┐                │
        │         │   ErrorHandler.php (NUEVO)      │                │
        │         │   (Clase Centralizada)          │                │
        │         │                                 │                │
        │         │  🎯 FUNCIONES PRINCIPALES:     │                │
        │         │                                 │                │
        │         │  • handleDatabaseException()    │                │
        │         │    └─ Lee errorInfo[0] = SQLSTATE      │        │
        │         │    └─ Busca en $sqlErrorMap           │        │
        │         │    └─ Traduce al español               │        │
        │         │                                 │                │
        │         │  • handleValidationException()  │                │
        │         │    └─ Captura errores lógica  │                │
        │         │                                 │                │
        │         │  • validateNotEmpty()          │                │
        │         │    └─ Valida parámetros       │                │
        │         │                                 │                │
        │         │  • logError()                  │                │
        │         │    └─ Escribe en logs/         │                │
        │         │       error_handler.log        │                │
        │         │                                 │                │
        │         │  • sendJSON()                  │                │
        │         │    └─ Retorna JSON + HTTP code │                │
        │         │                                 │                │
        │         └─────────────────────────────────┘                │
        │                   ▲                                         │
        │                   │ Lee                                     │
        │                   │                                         │
        │         ┌─────────┴──────────────────────┐                │
        │         │  PostgreSQL DATABASE           │                │
        │         │                                │                │
        │         │  • tab_usuarios               │                │
        │         │  • tab_menus                  │                │
        │         │  • tab_menu_usuarios          │                │
        │         │                                │                │
        │         │  ERRORES POSIBLES:            │                │
        │         │  • 23505 = Clave única       │                │
        │         │  • 23503 = Clave foránea     │                │
        │         │  • 42P01 = Tabla no existe   │                │
        │         │  • 08000 = Sin conexión      │                │
        │         │  ... (ver ErrorHandler.php) │                │
        │         └────────────────────────────────┘                │
        │                                                                │
        └────────────────────────────────────────────────────────────┘
                         │
                         │ Respuesta JSON
                         │ {status: 'success'|'error',
                         │  source: 'DATABASE'|'VALIDATION'|'NETWORK',
                         │  message: 'Texto traducido',
                         │  sqlstate: '23505'|null,
                         │  debug: {...}}
                         │
        ┌────────────────▼──────────────────────────────────┐
        │           NAVEGADOR - RECIBE JSON                 │
        │                                                    │
        │  JavaScript evalúa:                               │
        │  • data.status === 'success'?                    │
        │    ├─ Sí → mostrarExito()                        │
        │    │      ├─ Loguea en consola                  │
        │    │      ├─ Alert "✅ OPERACIÓN EXITOSA"        │
        │    │      └─ Limpia formulario                   │
        │    │                                              │
        │    └─ No → mostrarErrorCategorizado()            │
        │           ├─ Lee data.source                     │
        │           ├─ Elige icono (🔴⚠️📡)               │
        │           ├─ Loguea en consola con formato       │
        │           └─ Alert con icono + mensaje           │
        │                                                    │
        │  RESULTADO VISIBLE:                               │
        │  ┌──────────────────────────┐                     │
        │  │ 🔴 ERROR DE BASE DE DATOS │                    │
        │  │                           │                    │
        │  │ Violación de clave única. │                    │
        │  │ Este registro ya existe.  │                    │
        │  │                           │                    │
        │  │ (Código: 23505)           │                    │
        │  │      [Aceptar]            │                    │
        │  └──────────────────────────┘                     │
        │                                                    │
        │  CONSOLA (F12):                                   │
        │  ╔════ ERROR CATEGORIZADO ════╗                  │
        │  Origen: DATABASE                                │
        │  Mensaje: Violación de clave única...            │
        │  SQLSTATE: 23505                                 │
        │  ╚═══════════════════════════╝                   │
        └────────────────────────────────────────────────────┘
                         │
                         │
        ┌────────────────▼──────────────────────────────────┐
        │        SERVIDOR - ARCHIVO LOG (AUDITORÍA)         │
        │        logs/error_handler.log                     │
        │                                                    │
        │  [2026-03-03 14:30:45] DATABASE_ERROR |           │
        │  Code: 23505 | Message: duplicate key... |        │
        │  IP: 192.168.1.100                                │
        │                                                    │
        │  [2026-03-03 14:31:20] VALIDATION_ERROR |         │
        │  Code: N/A | Message: ID Usuario requerido |      │
        │  IP: 192.168.1.101                                │
        │                                                    │
        │  ... (todos los errores registrados)              │
        │                                                    │
        └────────────────────────────────────────────────────┘
```

---

## 📊 Flujos de Decisión

### Flujo: ¿Qué tipo de error es?

```
┌─ Se lanza excepción
│
├─ ¿Es PDOException?
│   ├─ SÍ → handleDatabaseException()
│   │   ├─ Lee errorInfo[0] (SQLSTATE)
│   │   ├─ Busca traducción
│   │   ├─ Source: "DATABASE"
│   │   └─ Retorna JSON con sqlstate
│   │
│   └─ NO
│       ├─ ¿Es Exception genérica?
│       │   ├─ SÍ → handleValidationException()
│       │   │   ├─ Message: del throw new Exception()
│       │   │   ├─ Source: "VALIDATION"
│       │   │   └─ Retorna JSON sin sqlstate
│       │   │
│       │   └─ NO
│       │       └─ Source: "UNKNOWN"
│       │
│       └─ ¿Es error de red (fetch fail)?
│           ├─ SÍ → JavaScript crea error
│           │   ├─ Source: "NETWORK"
│           │   └─ Muestra 📡 ERROR DE RED
│           │
│           └─ Mostrar al usuario
```

---

## 🔐 Información Visible en Cada Capa

```
┌─────────────────────────────────────────────────────────┐
│           USUARIO FINAL (Alert en pantalla)             │
│                                                         │
│  VE:                          NO VE:                   │
│  ✅ Categoría (icono)        ❌ Nombres de tablas     │
│  ✅ Mensaje simple            ❌ Queries SQL           │
│  ✅ Código SQLSTATE           ❌ Stack trace           │
│  ✅ Acción sugerida           ❌ Rutas del servidor    │
│                               ❌ Variables internas     │
└──────────────────────────────┬──────────────────────────┘
                               │
                ┌──────────────▼──────────────┐
                │  DESARROLLADOR (Consola F12) │
                │                              │
                │  VE ADEMÁS:                  │
                │  ✅ JSON completo            │
                │  ✅ Campo debug              │
                │  ✅ Timestamps               │
                │  ✅ Stack trace (debug)      │
                │  ❌ Contraseñas (excluidas) │
                └──────────────┬───────────────┘
                               │
                ┌──────────────▼──────────────┐
                │  ADMINISTRADOR (Log Server) │
                │                              │
                │  VE:                         │
                │  ✅ Todos los errores        │
                │  ✅ IP del usuario           │
                │  ✅ Timestamps exactos       │
                │  ✅ Código SQLSTATE          │
                │  ✅ Patrones de error        │
                │  ❌ Datos sensibles         │
                └──────────────────────────────┘
```

---

## 🎯 Puntos Clave de Control

```
PUNTO 1: ENTRADA (obtener_menus_usuario.php)
    ├─ ¿Parámetro usuario existe?
    ├─ ¿No está vacío?
    └─ Valida con ErrorHandler::validateNotEmpty()
           ├─ SÍ FALLA → Exception → VALIDATION error
           └─ SÍ OK → Continúa a BD

PUNTO 2: BASE DE DATOS
    ├─ SELECT FROM tab_menu_usuarios
    └─ ¿Hay error PDO?
           ├─ SÍ → PDOException → DATABASE error
           └─ NO → Retorna menús (puede ser vacío, NO es error)

PUNTO 3: RESPUESTA
    ├─ Estructura JSON unificada
    ├─ source: 'DATABASE' | 'VALIDATION'
    ├─ message: traducido al español
    └─ sqlstate: código si es BD


PUNTO 4: JAVASCRIPT (Navegador)
    ├─ ¿data.status === 'success'?
    │   ├─ SÍ → mostrarExito() + limpiar
    │   └─ NO → Continúa
    │
    ├─ ¿data.source?
    │   ├─ 'DATABASE' → 🔴 icono
    │   ├─ 'VALIDATION' → ⚠️ icono
    │   ├─ 'NETWORK' → 📡 icono
    │   └─ Mostrar alert categorizado
    │
    └─ Consola: Logs con estructura clara


PUNTO 5: LOG DEL SERVIDOR
    ├─ logError() escribe en archivo
    ├─ Incluye: timestamp, tipo, código, IP
    └─ Disponible para auditoría
```

---

## 🚀 Flujo de Liberación (Deployment)

```
DESARROLLO
   │
   ├─ Probar localmente (tests)
   │
   ├─ Verificar logs escriben
   │
   └─ ✅ Ready for staging

STAGING
   │
   ├─ Testing en ambiente similar a producción
   │
   ├─ Revisar patrones de errores
   │
   └─ ✅ Ready for production

PRODUCCIÓN
   │
   ├─ Monitorear logs/error_handler.log
   │
   ├─ Usuarios reciben mensajes claros
   │
   ├─ Admin puede analizar patrones
   │
   └─ ✅ Sistema en operación normal
```

---

## 📌 Conexiones Clave

```
ErrorHandler.php ←─────────────────────┐
     ↑                                   │
     │                                   │
obtener_menus                procesar_    │
_usuario.php ←───────────── perfil.php   │
     ↑                          ↑        │
     │                          │        │
JavaScript              JavaScript      │
  fetch()                 submit()       │
     ↑                          ↑        │
     │                          │        │
menu_usuarios.js ────────────────┴───── Manejo unificado
     ↓                                   ↓
mostrarErrorCategorizado()           logs/
mostrarExito()                    error_handler.log
```

