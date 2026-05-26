<?php
declare(strict_types=1);

if (!class_exists('AppConfig', false)) {
    return;
}

$dark = AppConfig::themeTokensDark();
$light = AppConfig::themeTokensLight();
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
