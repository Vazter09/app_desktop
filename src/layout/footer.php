    </main><!-- /.main-content -->
</div><!-- /.content-wrapper -->
</div><!-- /.app-wrapper -->

<div id="toast-container" class="toast-container smart-toast-container position-fixed bottom-0 end-0 p-3" aria-live="polite" aria-atomic="true"></div>
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
?>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="<?= htmlspecialchars($_asset_href) ?>js/smartcset-forms.js?v=<?= (int) $_v_forms ?>"></script>
<script src="<?= htmlspecialchars($_asset_href) ?>js/smartcset-toast.js?v=<?= (int) $_v_toast ?>"></script>
<script src="<?= htmlspecialchars($_asset_href) ?>js/smartcset-confirm.js?v=<?= (int) $_v_confirm ?>"></script>
<script src="<?= htmlspecialchars($_asset_href) ?>js/layout.js?v=<?= (int) $_v_layoutjs ?>"></script>
<?php if (isset($include_calculator) && $include_calculator): ?>
<script src="<?= htmlspecialchars($_asset_href) ?>js/menu_calculadora.js"></script>
<?php endif; ?>
<?php if (isset($extra_js)): ?>
<?= $extra_js ?>
<?php endif; ?>
</body>
</html>
