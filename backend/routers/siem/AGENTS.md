# AGENTS.md — SIEM routers

Módulo SIEM (mini Security Information & Event Management), consolidado 2026-07-06/07 (ver
CLAUDE.md Bug 16 y HANDOFF.md sesiones 2026-07-06/07). Reducido a 2 vistas el 2026-07-08
(se eliminaron Eventos/IPs Bloqueadas/Actividad Física — quedaban redundantes con Panel de
Control + Sesiones Activas) en
`frontend/web/pages/modulos/siem/{index,sesiones}/index.php`, funciones en
`database/functions/siem/`, 1 endpoint AJAX en `backend/routers/siem/v1/`.

## Menús (submenú de SGA `20`, NO menú raíz — ver Bug 12 en CLAUDE.md)

| ID | Vista | Función SQL |
|----|-------|-------------|
| `21101` | Panel de Control (`index.php`) | `fun_siem_dashboard.sql` |
| `21103` | Sesiones (`sesiones/index.php`) | `fun_siem_sesiones.sql` + `forzar_sesion.php` |

## Patrones obligatorios para código nuevo en este módulo

**Control de acceso** — vistas y endpoints AJAX, siempre con el helper (NUNCA query manual a
`tab_menu_usuarios`, NUNCA solo `isset($_SESSION['id_usuario'])`):
```php
if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '211XX')) {
    // vista: http_response_code(403); die(...);
    // endpoint: RouterResponse::fail('No tienes permiso para esta acción.', 403);
}
```

**Timezone** — los timestamps se guardan en UTC (`DB_TIMEZONE`), se muestran en
`APP_TIMEZONE` (America/Bogota):
- Mostrar hora/fecha: `smartcsetFormatDbTimestamp($valor, 'H:i:s')` — NUNCA
  `date('H:i:s', strtotime($valor))`.
- Comparar contra "hoy" o filtros de fecha en SQL: la función recibe
  `wzona_horaria TEXT DEFAULT 'America/Bogota'` y compara con
  `(columna::TIMESTAMPTZ AT TIME ZONE wzona_horaria)::DATE` — NUNCA `DATE(columna) = CURRENT_DATE`
  a secas (compara en UTC, no en local). PHP pasa `smartcsetAppTimezone()` como parámetro.
- Si cambia la aridad de una función (se agrega `wzona_horaria` a una ya desplegada), agregar
  `DROP FUNCTION IF EXISTS nombre(firma_vieja)` antes del `CREATE OR REPLACE` — PostgreSQL trata
  distinto número de argumentos como funciones distintas (misma lección de E3).

**Cache-busting CSS** — todas las vistas usan `modulosProjectRoot()` + `filemtime()`:
```php
$_root  = modulosProjectRoot();
$_css_v = @filemtime($_root . '/frontend/web/public/assets/css/siem.css') ?: time();
```
El path completo (`/frontend/web/public/assets/css/...`) es obligatorio — `modulosProjectRoot()`
devuelve la raíz del proyecto, no la carpeta de assets.

**Llamadas AJAX desde una vista** — `SmartcsetHttp` (en `js/services/http-client.js`) **no se
carga globalmente** desde el footer; cada vista que lo usa debe incluirlo en su `$extra_js`:
```php
$_v_http = @filemtime($_root . '/frontend/web/public/assets/js/services/http-client.js') ?: time();
$extra_js = '<script src="' . htmlspecialchars(smartcsetAsset('js/services/http-client.js'))
    . '?v=' . (int) $_v_http . '"></script>' . <<<HTML
<script>
SmartcsetHttp.post(url, payload)
    .then(function () { /* éxito: payload.data ya resuelto */ })
    .catch(function (err) { SmartToast.error(err.message); }); // NUNCA "SmartcsetToast" (no existe)
</script>
HTML;
```
`SmartcsetHttp` resuelve con `payload.data` en éxito y **lanza** `Error(msg)` cuando `ok !== true`
— el mensaje de negocio llega siempre por `.catch()`, nunca por un `if (res.ok)` dentro de `.then()`.

**Sin CDN externo** — cualquier librería JS externa debe vendorizarse en
`frontend/web/public/assets/js/vendor/` (commiteada al repo). No agregar `<script>` apuntando a
`cdn.jsdelivr.net` ni ningún otro CDN — el servidor institucional puede no tener salida a
internet. (Chart.js se vendorizó para la gráfica de eventos por hora que existió en el Panel de
Control; esa gráfica se eliminó el 2026-07-08 — Bug 18 en CLAUDE.md — junto con la carpeta
`vendor/chart-4.4.0/` si no la usa ningún otro módulo.)

**Auto-refresh sin recargar la página** (Panel de Control, desde 2026-07-08 — Bug 18 en
CLAUDE.md): el contenido de `index.php` vive en `dashboard_fragment.php` (incluido tanto en el
render completo como en la respuesta a `?partial=1`), y `siem_dashboard.js` hace polling cada 20s
reutilizando `SmartcsetListado.loadIntoHost()` (ya usado en listados de personas) para no
duplicar el render en JS. Si se agrega una vista nueva a este módulo que necesite refrescarse
sola, replicar este patrón (fragment + `?partial=1` + `SmartcsetListado`) en vez de inventar uno
con `SmartcsetHttp`/JSON — es el que ya existe y evita mantener el mismo HTML en dos lenguajes.
El check de `usuarioTieneMenu()` debe ir **antes** del branch `partial`, nunca después.

## Qué NO tocar sin entender primero

- No reintroducir la numeración vieja `06`/`06xx` (era de antes de la reorganización de menús en
  3 abuelos SGI/SGA/SAA) — SIEM vive bajo `211xx` (submenú de SGA `20`).
- No asumir que `usuarioTieneMenu()` está disponible sin `helpers.php` — ya se carga desde
  `prepare.php`, no hace falta `require_once` explícito adicional en los endpoints.
- No recrear los submenús `21102`/`21104`/`21105` (Eventos/IPs Bloqueadas/Actividad Física) sin
  entender por qué se eliminaron (Bug 18, CLAUDE.md) — si hace falta esa funcionalidad de nuevo,
  revisar el historial de esos archivos en git en vez de reinventarlos desde cero.
