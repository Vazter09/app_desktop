/**
 * Configuración del módulo de personas (admin).
 */
(function () {
    'use strict';

    function showFlash(message, tipo) {
        if (typeof window.smartcsetShowToast === 'function') {
            window.smartcsetShowToast(message, tipo || 'success');
            return;
        }
        window.location.reload();
    }

    document.addEventListener('DOMContentLoaded', function () {
        const form = document.getElementById('form-config-personas');
        if (!form || typeof SmartcsetAdminRouter === 'undefined') {
            return;
        }

        form.addEventListener('submit', async function (e) {
            const submitter = e.submitter;
            if (!submitter) {
                return;
            }
            e.preventDefault();

            if (submitter.name === 'btn_restaurar_registro') {
                try {
                    const data = await SmartcsetAdminRouter.restaurarConfigPersonas();
                    showFlash(data.message || 'Configuración restaurada.', 'success');
                    setTimeout(() => window.location.reload(), 800);
                } catch (err) {
                    showFlash(err.message || 'Error al restaurar.', 'danger');
                }
                return;
            }

            if (submitter.name === 'btn_guardar_registro') {
                const fd = new FormData(form);
                try {
                    const data = await SmartcsetAdminRouter.guardarConfigPersonas(fd);
                    showFlash(data.message || 'Configuración guardada.', 'success');
                    setTimeout(() => window.location.reload(), 800);
                } catch (err) {
                    showFlash(err.message || 'Error al guardar.', 'danger');
                }
            }
        });
    });
})();
