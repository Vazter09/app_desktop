<?php
/**
 * Toast + confirm modal + scripts para páginas fuera del layout principal.
 * Definir antes de incluir: $ui_assets_prefix (ej. '../../' desde src/auth, '' desde raíz)
 */
$_ui_prefix = $ui_assets_prefix ?? '../../';
$_ui_root   = dirname(__DIR__, 2);
$_v_forms   = @filemtime($_ui_root . '/js/smartcset-forms.js') ?: time();
$_v_toast   = @filemtime($_ui_root . '/js/smartcset-toast.js') ?: time();
$_v_confirm = @filemtime($_ui_root . '/js/smartcset-confirm.js') ?: time();
?>
<div id="toast-container" class="toast-container smart-toast-container position-fixed bottom-0 end-0 p-3" aria-live="polite" aria-atomic="true"></div>
<?php include __DIR__ . '/partials/ui_confirm_modal.php'; ?>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="<?= htmlspecialchars($_ui_prefix) ?>js/smartcset-forms.js?v=<?= (int) $_v_forms ?>"></script>
<script src="<?= htmlspecialchars($_ui_prefix) ?>js/smartcset-toast.js?v=<?= (int) $_v_toast ?>"></script>
<script src="<?= htmlspecialchars($_ui_prefix) ?>js/smartcset-confirm.js?v=<?= (int) $_v_confirm ?>"></script>
