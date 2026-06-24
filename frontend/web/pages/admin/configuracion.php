<?php
require_once dirname(__DIR__, 2) . '/init.php';
require_once dirname(__DIR__, 4) . '/backend/core/LogoUpload.php';
require_once dirname(__DIR__, 4) . '/backend/core/ConfigSistemaDefaults.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../../index.php');
    exit();
}

if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Solo administradores pueden modificar la configuración del sistema.');
}

$w_mensaje     = '';
$w_tipo_alerta = 'success';


$config = [];
if ($stmt_get_config instanceof PDOStatement) {
    try {
        $stmt_get_config->execute();
        $config = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];
    } catch (PDOException) {
        $config = [];
    }
}

$c = $config;

/**
 * Botón restaurar dentro de cada tarjeta (mismo formulario principal).
 */
function configuracionBotonRestaurar(string $section, string $tituloCorto): void
{
    $label = ConfigSistemaDefaults::sectionLabel($section);
    ?>
    <div class="col-12 config-section-restore d-flex justify-content-end">
        <button type="submit" name="btn_restaurar_seccion" value="<?= htmlspecialchars($section, ENT_QUOTES, 'UTF-8') ?>"
                class="btn btn-sm btn-outline-secondary" formnovalidate
                data-smart-confirm
                data-smart-confirm-title="Restaurar <?= htmlspecialchars($tituloCorto, ENT_QUOTES, 'UTF-8') ?>"
                data-smart-confirm-message="¿Restaurar solo la <?= htmlspecialchars($label, ENT_QUOTES, 'UTF-8') ?> a los valores por defecto de la migración?"
                data-smart-confirm-ok="Restaurar"
                data-smart-confirm-variant="warning">
            <i class="bi bi-arrow-counterclockwise me-1"></i>Restaurar <?= htmlspecialchars($tituloCorto, ENT_QUOTES, 'UTF-8') ?>
        </button>
    </div>
    <?php
}
$page_title     = 'Config. sistema';
$active_menu_id = '0401';
$wnom_usuario   = $_SESSION['nom_usuario'];
$logo_path_db   = $c['path_logo'] ?? 'assets/img/logo-sena.png';
$logo_preview_url = htmlspecialchars(smartcsetLogoUrl(), ENT_QUOTES, 'UTF-8');
$extra_css = '';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<form method="POST" id="form-config-sistema" class="row g-3" enctype="multipart/form-data" action="#">
    <div class="col-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2">
                <strong><i class="bi bi-gear-fill me-2"></i>General y módulo de registro</strong>
            </div>
            <div class="card-body">
                <div class="config-general">
                    <div class="config-general__fields">
                        <div class="config-field-group">
                            <p class="config-field-group__title">Identidad</p>
                            <div>
                                <label class="form-label small fw-bold" for="txt_nom_sistema">Nombre del sistema</label>
                                <input type="text" name="txt_nom_sistema" id="txt_nom_sistema"
                                       class="form-control form-control-sm"
                                       value="<?= htmlspecialchars($c['nom_sistema'] ?? 'SmartCSET') ?>" required>
                            </div>
                        </div>

                        <div class="config-field-group">
                            <p class="config-field-group__title">Colores corporativos</p>
                            <div class="row g-2 config-general__colors">
                                <div class="col-6 col-md-3">
                                    <label class="form-label small" for="txt_color_primario">Color primario</label>
                                    <input type="color" name="txt_color_primario" id="txt_color_primario"
                                           class="form-control form-control-color w-100"
                                           value="<?= htmlspecialchars($c['color_primario'] ?? '#2E4731') ?>">
                                </div>
                                <div class="col-6 col-md-3">
                                    <label class="form-label small" for="txt_color_secundario">Color secundario</label>
                                    <input type="color" name="txt_color_secundario" id="txt_color_secundario"
                                           class="form-control form-control-color w-100"
                                           value="<?= htmlspecialchars($c['color_secundario'] ?? '#6B8E23') ?>">
                                </div>
                            </div>
                            <p class="small text-muted mb-0 mt-1">Afectan menú, login y pantallas administrativas.</p>
                        </div>

                    </div>

                    <aside class="config-general__logo" aria-label="Logo del sistema">
                        <label class="form-label small fw-bold d-block mb-2">Logo del sistema</label>
                        <div class="file-drop file-drop--gallery" id="logo-file-drop" data-max-files="1">
                            <div class="file-drop__preview<?= empty($logo_path_db) ? ' is-empty' : '' ?>">
                                <img src="<?= $logo_preview_url ?>" alt="Logo actual" class="file-drop__preview-img"
                                     id="logo-upload-preview-img"
                                     onerror="this.classList.add('d-none'); this.closest('.file-drop__preview')?.classList.add('is-empty');">
                                <div class="file-drop__meta">
                                    <span class="file-drop__preview-label">Vista previa</span>
                                    <span class="file-drop__path" id="logo-upload-path"><?= htmlspecialchars($logo_path_db) ?></span>
                                </div>
                            </div>
                            <div class="file-drop__zone" tabindex="0" role="button"
                                 aria-label="Subir logo: arrastre o seleccione un archivo">
                                <div class="file-drop__zone-icon" aria-hidden="true">
                                    <i class="bi bi-image"></i>
                                </div>
                                <div class="file-drop__zone-title">Subir logo institucional</div>
                                <p class="file-drop__zone-hint">
                                    Arrastre la imagen aquí o haga clic para buscar
                                </p>
                                <p class="file-drop__zone-meta">1 archivo · PNG, JPG, GIF o WebP · máx. 5 MB</p>
                                <button type="button" class="file-drop__btn-select" id="logo-upload-trigger">
                                    <i class="bi bi-upload me-1" aria-hidden="true"></i>Seleccionar imagen
                                </button>
                                <input type="file" name="logo_file" id="logo_file" class="file-drop__input"
                                       accept="image/png,image/jpeg,image/gif,image/webp"
                                       data-max-files="1">
                            </div>
                            <p class="file-drop__status" id="logo-upload-status" role="status" aria-live="polite"></p>
                            <input type="hidden" name="txt_path_logo" id="txt_path_logo"
                                   value="<?= htmlspecialchars($logo_path_db) ?>">
                        </div>
                    </aside>

                    <div class="config-general__footer config-section-restore d-flex justify-content-end">
                        <?php
                        $section = ConfigSistemaDefaults::SECTION_GENERAL;
                        $tituloCorto = 'sección general';
                        $label = ConfigSistemaDefaults::sectionLabel($section);
                        ?>
                        <button type="submit" name="btn_restaurar_seccion" value="<?= htmlspecialchars($section, ENT_QUOTES, 'UTF-8') ?>"
                                class="btn btn-sm btn-outline-secondary" formnovalidate
                                data-smart-confirm
                                data-smart-confirm-title="Restaurar <?= htmlspecialchars($tituloCorto, ENT_QUOTES, 'UTF-8') ?>"
                                data-smart-confirm-message="¿Restaurar solo la <?= htmlspecialchars($label, ENT_QUOTES, 'UTF-8') ?> a los valores por defecto de la migración?"
                                data-smart-confirm-ok="Restaurar"
                                data-smart-confirm-variant="warning">
                            <i class="bi bi-arrow-counterclockwise me-1"></i>Restaurar <?= htmlspecialchars($tituloCorto, ENT_QUOTES, 'UTF-8') ?>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2">
                <strong><i class="bi bi-palette-fill me-2"></i>Tema oscuro (global)</strong>
            </div>
            <div class="card-body row g-2">
                <?php
                $themeFields = [
                    'txt_theme_bg_deep' => ['Fondo principal', 'color', '#020917'],
                    'txt_theme_bg_card' => ['Fondo tarjetas', 'color', '#060f24'],
                    'txt_theme_accent' => ['Acento', 'color', '#00e5b0'],
                    'txt_theme_text_primary' => ['Texto principal', 'color', '#e8f4ff'],
                    'txt_theme_blue' => ['Azul', 'color', '#4a9eff'],
                    'txt_theme_purple' => ['Morado', 'color', '#9b6dff'],
                    'txt_theme_orange' => ['Naranja', 'color', '#ff7b2e'],
                ];
                foreach ($themeFields as $name => [$label, $type, $def]):
                    $key = str_replace('txt_', '', $name);
                    $val = $c[$key] ?? $def;
                ?>
                <div class="col-md-3">
                    <label class="form-label small"><?= htmlspecialchars($label) ?></label>
                    <input type="color" name="<?= $name ?>" class="form-control form-control-color"
                           value="<?= htmlspecialchars((string) $val) ?>">
                </div>
                <?php endforeach; ?>
                <div class="col-md-3">
                    <label class="form-label small">Fuente títulos</label>
                    <input type="text" name="txt_theme_font_display" class="form-control form-control-sm"
                           value="<?= htmlspecialchars($c['theme_font_display'] ?? 'Orbitron') ?>">
                </div>
                <div class="col-md-3">
                    <label class="form-label small">Fuente cuerpo</label>
                    <input type="text" name="txt_theme_font_body" class="form-control form-control-sm"
                           value="<?= htmlspecialchars($c['theme_font_body'] ?? 'Rajdhani') ?>">
                </div>
                <input type="hidden" name="txt_theme_bg_panel" value="<?= htmlspecialchars($c['theme_bg_panel'] ?? 'rgba(6, 15, 36, 0.85)') ?>">
                <input type="hidden" name="txt_theme_accent_dim" value="<?= htmlspecialchars($c['theme_accent_dim'] ?? 'rgba(0, 245, 255, 0.15)') ?>">
                <input type="hidden" name="txt_theme_text_muted" value="<?= htmlspecialchars($c['theme_text_muted'] ?? 'rgba(150,180,220,0.7)') ?>">
                <input type="hidden" name="txt_theme_border" value="<?= htmlspecialchars($c['theme_border'] ?? 'rgba(0,245,255,0.2)') ?>">
                <input type="hidden" name="txt_theme_error" value="<?= htmlspecialchars($c['theme_error'] ?? '#ff3c6e') ?>">
                <input type="hidden" name="txt_theme_success" value="<?= htmlspecialchars($c['theme_success'] ?? '#00e5b0') ?>">
                <?php configuracionBotonRestaurar(ConfigSistemaDefaults::SECTION_THEME_DARK, 'tema oscuro'); ?>
            </div>
        </div>
    </div>

    <div class="col-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2">
                <strong><i class="bi bi-sun-fill me-2"></i>Tema claro</strong>
            </div>
            <div class="card-body row g-2">
                <div class="col-md-3">
                    <label class="form-label small">Fondo claro</label>
                    <input type="color" name="txt_theme_light_bg_deep" class="form-control form-control-color"
                           value="<?= htmlspecialchars($c['theme_light_bg_deep'] ?? '#f5f7fb') ?>">
                </div>
                <div class="col-md-3">
                    <label class="form-label small">Acento claro</label>
                    <input type="color" name="txt_theme_light_accent" class="form-control form-control-color"
                           value="<?= htmlspecialchars($c['theme_light_accent'] ?? '#0b74c7') ?>">
                </div>
                <div class="col-md-3">
                    <label class="form-label small">Texto claro</label>
                    <input type="color" name="txt_theme_light_text_primary" class="form-control form-control-color"
                           value="<?= htmlspecialchars($c['theme_light_text_primary'] ?? '#111827') ?>">
                </div>
                <input type="hidden" name="txt_theme_light_bg_card" value="<?= htmlspecialchars($c['theme_light_bg_card'] ?? '#ffffff') ?>">
                <input type="hidden" name="txt_theme_light_text_muted" value="<?= htmlspecialchars($c['theme_light_text_muted'] ?? 'rgba(55,65,81,0.8)') ?>">
                <?php configuracionBotonRestaurar(ConfigSistemaDefaults::SECTION_THEME_LIGHT, 'tema claro'); ?>
            </div>
        </div>
    </div>

    <div class="col-12 d-flex flex-wrap align-items-center gap-2">
        <button type="submit" name="btn_guardar_config" class="btn btn-sm fw-bold text-white"
                style="background:var(--v-oscuro);">
            <i class="bi bi-save-fill me-1"></i>Guardar configuración
        </button>
    </div>
</form>

<?php
$_ar = dirname(__DIR__, 2) . '/public/assets';
$v_logo_js = @filemtime($_ar . '/js/core/logo-upload.js') ?: time();
include smartcsetLayoutPath('footer.php');
?>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/http-client.js') ?: time()) ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/admin-router.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/admin-router.js') ?: time()) ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/configuracion.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/core/configuracion.js') ?: time()) ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/logo-upload.js')) ?>?v=<?= (int) $v_logo_js ?>"></script>
