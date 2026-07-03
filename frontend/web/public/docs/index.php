<?php
declare(strict_types=1);

/**
 * Swagger UI — spec embebido desde openapi.json (sin fetch YAML).
 * Assets locales en vendor/; fallback a CDN si no existen.
 */

$specPath = __DIR__ . '/openapi.json';
if (!is_file($specPath)) {
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo "openapi.json no generado. Ejecute: php scripts/tools/generate_openapi.php\n";
    exit;
}

$specJson = file_get_contents($specPath);
if ($specJson === false) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'No se pudo leer openapi.json';
    exit;
}

$vendorCss = __DIR__ . '/vendor/swagger-ui.css';
$vendorBundle = __DIR__ . '/vendor/swagger-ui-bundle.js';
$vendorPreset = __DIR__ . '/vendor/swagger-ui-standalone-preset.js';
$cdnBase = 'https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14';

$cssHref = is_file($vendorCss) ? 'vendor/swagger-ui.css' : $cdnBase . '/swagger-ui.css';
$bundleSrc = is_file($vendorBundle) ? 'vendor/swagger-ui-bundle.js' : $cdnBase . '/swagger-ui-bundle.js';
$presetSrc = is_file($vendorPreset) ? 'vendor/swagger-ui-standalone-preset.js' : $cdnBase . '/swagger-ui-standalone-preset.js';

header('Content-Type: text/html; charset=utf-8');
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
    const spec = <?= $specJson ?>;
    window.onload = function () {
      if (typeof SwaggerUIBundle === 'undefined') {
        document.getElementById('swagger-ui').innerHTML =
          '<p style="padding:1.5rem;font-family:system-ui,sans-serif">No se cargó Swagger UI. ' +
          'Ejecute <code>bash scripts/tools/setup_swagger_ui_vendor.sh</code> o verifique acceso a CDN.</p>';
        return;
      }
      SwaggerUIBundle({
        spec: spec,
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
