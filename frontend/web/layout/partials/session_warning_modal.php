<?php if (session_status() === PHP_SESSION_ACTIVE && !empty($_SESSION['id_sesion'])): ?>
<div class="modal fade" id="smartcsetSesionWarningModal" tabindex="-1"
     aria-labelledby="sesionWarningTitle" aria-hidden="true"
     data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content border-0 shadow smart-confirm-content">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title d-flex align-items-center gap-2 mb-0" id="sesionWarningTitle">
                    <i class="bi bi-clock-history text-warning"></i>
                    <span>Sesión por expirar</span>
                </h5>
            </div>
            <div class="modal-body pt-2 pb-2 text-secondary small">
                Su sesión cerrará en
                <strong id="sesion-warning-contador" class="text-danger">2:00</strong>
                por inactividad.
            </div>
            <div class="modal-footer border-0 pt-0 gap-2">
                <button type="button" id="sesion-warning-renovar"
                        class="btn btn-success btn-sm px-3">
                    <i class="bi bi-arrow-clockwise me-1"></i>Seguir activo
                </button>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>
