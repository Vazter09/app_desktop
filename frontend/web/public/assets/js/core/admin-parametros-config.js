/**
 * Configuración de parámetros generales del centro (admin).
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
        const form = document.getElementById('form-config-pmtros');
        if (!form || typeof SmartcsetAdminRouter === 'undefined') {
            return;
        }

        form.addEventListener('submit', async function (e) {
            const submitter = e.submitter;
            if (!submitter) {
                return;
            }
            e.preventDefault();

            if (submitter.name === 'btn_restaurar_pmtros') {
                try {
                    const data = await SmartcsetAdminRouter.restaurarPmtrosGrales();
                    showFlash(data.message || 'Parámetros restaurados.', 'success');
                    setTimeout(() => window.location.reload(), 800);
                } catch (err) {
                    showFlash(err.message || 'Error al restaurar.', 'danger');
                }
                return;
            }

            if (submitter.name === 'btn_guardar_pmtros') {
                const fd = new FormData(form);
                try {
                    const data = await SmartcsetAdminRouter.guardarPmtrosGrales(fd);
                    showFlash(data.message || 'Parámetros guardados.', 'success');
                    setTimeout(() => window.location.reload(), 800);
                } catch (err) {
                    showFlash(err.message || 'Error al guardar.', 'danger');
                }
            }
        });
    });
})();
