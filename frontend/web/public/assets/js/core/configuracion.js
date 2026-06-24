/**
 * Configuración del sistema — envío vía router JSON.
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
        const form = document.getElementById('form-config-sistema');
        if (!form || typeof SmartcsetAdminRouter === 'undefined') {
            return;
        }

        form.addEventListener('submit', async function (e) {
            const submitter = e.submitter;
            if (!submitter) {
                return;
            }

            if (submitter.name === 'btn_restaurar_seccion') {
                e.preventDefault();
                const section = submitter.value;
                try {
                    const data = await SmartcsetAdminRouter.restaurarConfig(section);
                    showFlash(data.message || 'Sección restaurada.', 'success');
                    setTimeout(() => window.location.reload(), 800);
                } catch (err) {
                    showFlash(err.message || 'Error al restaurar.', 'danger');
                }
                return;
            }

            if (submitter.name === 'btn_guardar_config') {
                e.preventDefault();
                const fd = new FormData(form);
                fd.delete('btn_restaurar_seccion');
                try {
                    const data = await SmartcsetAdminRouter.guardarConfig(fd);
                    showFlash(data.message || 'Configuración guardada.', 'success');
                    setTimeout(() => window.location.reload(), 800);
                } catch (err) {
                    showFlash(err.message || 'Error al guardar.', 'danger');
                }
            }
        });
    });
})();
