<?php
declare(strict_types=1);

/**
 * Swagger UI — carga openapi.json (válido; no usar openapi.yaml generado con sintaxis inline).
 * Assets locales en vendor/; fallback a CDN si no existen.
 */

require_once dirname(__DIR__, 4) . '/backend/core/config.php';
require_once dirname(__DIR__, 4) . '/backend/core/helpers.php';

$specPath = __DIR__ . '/openapi.json';
if (!is_file($specPath)) {
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo "openapi.json no generado. Ejecute: php scripts/tools/generate_openapi.php\n";
    exit;
}

$docsBase = smartcsetUrl('/docs/');

$vendorCss = __DIR__ . '/vendor/swagger-ui.css';
$vendorBundle = __DIR__ . '/vendor/swagger-ui-bundle.js';
$vendorPreset = __DIR__ . '/vendor/swagger-ui-standalone-preset.js';
$cdnBase = 'https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14';

$cssHref = is_file($vendorCss) ? $docsBase . 'vendor/swagger-ui.css' : $cdnBase . '/swagger-ui.css';
$bundleSrc = is_file($vendorBundle) ? $docsBase . 'vendor/swagger-ui-bundle.js' : $cdnBase . '/swagger-ui-bundle.js';
$presetSrc = is_file($vendorPreset) ? $docsBase . 'vendor/swagger-ui-standalone-preset.js' : $cdnBase . '/swagger-ui-standalone-preset.js';
$specUrl = $docsBase . 'openapi.json';

header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');
header('Pragma: no-cache');
header("Content-Security-Policy: default-src 'self'; script-src 'self' https://cdn.jsdelivr.net https://unpkg.com 'unsafe-inline'; style-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; img-src 'self' data:; connect-src 'self';");
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SmartCSET API — OpenAPI</title>
  <link rel="stylesheet" href="<?= htmlspecialchars($cssHref, ENT_QUOTES, 'UTF-8') ?>">
  <style>
    body { margin: 0; background: #fafafa; }
    .dev-banner {
      background: #004d40;
      color: #fff;
      padding: 0.65rem 1.25rem;
      font-family: system-ui, sans-serif;
      font-size: 0.9rem;
    }
    .dev-banner strong { font-weight: 600; }
    #swagger-ui .topbar { display: none; }
  </style>
</head>
<body>
  <div class="dev-banner">
    <strong>Documentación de desarrollo</strong> — SmartCSET API v1.
    No exponer en producción sin autenticación adicional.
  </div>
  <div id="swagger-ui"></div>
  <script src="<?= htmlspecialchars($bundleSrc, ENT_QUOTES, 'UTF-8') ?>"></script>
  <script src="<?= htmlspecialchars($presetSrc, ENT_QUOTES, 'UTF-8') ?>"></script>
  <script>
    window.onload = function () {
      if (typeof SwaggerUIBundle === 'undefined') {
        document.getElementById('swagger-ui').innerHTML =
          '<p style="padding:1.5rem;font-family:system-ui,sans-serif">No se cargó Swagger UI. ' +
          'Ejecute <code>bash scripts/tools/setup_swagger_ui_vendor.sh</code> o verifique acceso a CDN.</p>';
        return;
      }
      SwaggerUIBundle({
        url: <?= json_encode($specUrl, JSON_UNESCAPED_SLASHES) ?>,
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
        layout: 'StandaloneLayout',
        validatorUrl: null,
        tryItOutEnabled: true,
        persistAuthorization: true,
      });
    };
  </script>
</body>
</html>
