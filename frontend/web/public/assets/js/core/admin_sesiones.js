/**
 * Admin sesiones activas — cierre vía router JSON.
 */
(function () {
    'use strict';

    function showFlash(message, tipo) {
        if (typeof window.smartcsetShowToast === 'function') {
            window.smartcsetShowToast(message, tipo || 'success');
            setTimeout(() => window.location.reload(), 600);
            return;
        }
        window.location.reload();
    }

    document.addEventListener('DOMContentLoaded', function () {
        if (typeof SmartcsetAdminRouter === 'undefined') {
            return;
        }

        document.querySelectorAll('form.form-cerrar-sesion').forEach(function (form) {
            form.addEventListener('submit', async function (e) {
                e.preventDefault();
                const input = form.querySelector('[name="hid_id_sesion"]');
                const id = input ? parseInt(input.value, 10) : 0;
                if (id < 1) {
                    return;
                }
                try {
                    const data = await SmartcsetAdminRouter.cerrarSesion(id);
                    showFlash(data.message || 'Sesión cerrada.', 'success');
                } catch (err) {
                    showFlash(err.message || 'No se pudo cerrar la sesión.', 'danger');
                }
            });
        });
    });
})();
