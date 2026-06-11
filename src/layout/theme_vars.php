<?php
declare(strict_types=1);

if (!class_exists('AppConfig', false)) {
    return;
}

$dark = AppConfig::themeTokensDark();
$light = array_merge(AppConfig::themeTokensLight(), [
    // Superficies de listados/tablas: en :root vienen del tema oscuro y no deben filtrarse al modo claro.
    '--table-surface-bg' => 'var(--bg-card, #ffffff)',
    '--surface-border'   => AppConfig::hexToRgba(AppConfig::colorPrimario(), 0.16),
    '--surface-hover'    => AppConfig::hexToRgba(AppConfig::colorSecundario(), 0.1),
    '--grid-line'        => AppConfig::hexToRgba(AppConfig::colorPrimario(), 0.06),
]);
$fontDisplay = htmlspecialchars(AppConfig::fontDisplay(), ENT_QUOTES, 'UTF-8');
$fontBody = htmlspecialchars(AppConfig::fontBody(), ENT_QUOTES, 'UTF-8');

$emitVars = static function (array $tokens): string {
    $lines = [];
    foreach ($tokens as $name => $value) {
        $safe = htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
        $lines[] = "    {$name}: {$safe};";
    }
    return implode("\n", $lines);
};
?>
<style id="smartcset-theme-vars">
:root {
<?= $emitVars($dark) ?>

}
.light-theme {
<?= $emitVars($light) ?>

}
body.registro-theme {
    font-family: '<?= $fontBody ?>', sans-serif;
}
body.registro-theme .sys-logo,
body.registro-theme .login-brand-logo,
body.registro-theme .section-heading {
    font-family: '<?= $fontDisplay ?>', sans-serif;
}
</style>
