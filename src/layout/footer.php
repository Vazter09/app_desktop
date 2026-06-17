    </main><!-- /.main-content -->
</div><!-- /.content-wrapper -->
</div><!-- /.app-wrapper -->

<div id="toast-container" class="toast-container smart-toast-container position-fixed bottom-0 end-0 p-3" aria-live="polite" aria-atomic="true"></div>
<?php
if (
    session_status() === PHP_SESSION_ACTIVE
    && !empty($_SESSION['id_sesion'])
    && !empty($_SESSION['id_usuario'])
    && defined('SESION_HEARTBEAT_SEG')
):
    if (!function_exists('smartcsetSesionHeartbeatUrl')) {
        require_once dirname(__DIR__) . '/core/helpers.php';
    }
    $_hb_menu = isset($active_menu_id) ? (string) $active_menu_id : '';
?>
<div id="smartcset-sesion-presencia" class="d-none"
     data-heartbeat-url="<?= htmlspecialchars(smartcsetSesionHeartbeatUrl()) ?>"
     data-heartbeat-seg="<?= (int) SESION_HEARTBEAT_SEG ?>"
     <?php if ($_hb_menu !== ''): ?>data-active-menu-id="<?= htmlspecialchars($_hb_menu) ?>"<?php endif; ?>></div>
<?php endif; ?>
<?php include __DIR__ . '/partials/ui_confirm_modal.php'; ?>

<?php
$_asset_href = $smartcset_asset_href ?? '../../';
if (!isset($_asset_root)) {
    $_asset_root = dirname(__DIR__, 2);
}
$_v_forms   = @filemtime($_asset_root . '/js/smartcset-forms.js') ?: time();
$_v_toast   = @filemtime($_asset_root . '/js/smartcset-toast.js') ?: time();
$_v_confirm = @filemtime($_asset_root . '/js/smartcset-confirm.js') ?: time();
$_v_layoutjs = @filemtime($_asset_root . '/js/layout.js') ?: time();
$_v_presencia = @filemtime($_asset_root . '/js/smartcset-presencia.js') ?: time();
$_cargar_presencia = session_status() === PHP_SESSION_ACTIVE
    && !empty($_SESSION['id_sesion'])
    && !empty($_SESSION['id_usuario']);
?>
<?php
$bootstrap_vendor_mode = 'scripts';
$bootstrap_asset_href = $_asset_href;
include __DIR__ . '/partials/bootstrap_vendor.php';
?>
<script src="<?= htmlspecialchars($_asset_href) ?>js/smartcset-forms.js?v=<?= (int) $_v_forms ?>"></script>
<script src="<?= htmlspecialchars($_asset_href) ?>js/smartcset-toast.js?v=<?= (int) $_v_toast ?>"></script>
<script src="<?= htmlspecialchars($_asset_href) ?>js/smartcset-confirm.js?v=<?= (int) $_v_confirm ?>"></script>
<script src="<?= htmlspecialchars($_asset_href) ?>js/layout.js?v=<?= (int) $_v_layoutjs ?>"></script>
<?php if ($_cargar_presencia): ?>
<script src="<?= htmlspecialchars($_asset_href) ?>js/smartcset-presencia.js?v=<?= (int) $_v_presencia ?>"></script>
<?php endif; ?>
<?php if (isset($extra_js)): ?>
<?= $extra_js ?>
<?php endif; ?>
</body>
</html>
