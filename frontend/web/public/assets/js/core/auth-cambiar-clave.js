/**
 * Cambio de contraseña autenticado — router JSON.
 */
(function () {
    'use strict';

    history.pushState(null, null, location.href);
    window.onpopstate = function () {
        history.go(1);
    };

    let hasChanges = false;
    document.addEventListener('input', function (e) {
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') {
            hasChanges = true;
        }
    });
    window.addEventListener('beforeunload', function (e) {
        if (hasChanges) {
            e.preventDefault();
            e.returnValue = '';
        }
    });

    document.addEventListener('DOMContentLoaded', function () {
        const form = document.getElementById('form-cambiar-clave');
        if (!form || typeof SmartcsetAuthRouter === 'undefined') {
            return;
        }

        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            hasChanges = false;
            const passAntigua = (form.querySelector('[name="wpass_antigua"]') || {}).value || '';
            const passNueva = (form.querySelector('[name="wpass_nueva"]') || {}).value || '';

            try {
                const data = await SmartcsetAuthRouter.cambiarClave(passAntigua, passNueva);
                if (typeof window.smartcsetShowToast === 'function') {
                    window.smartcsetShowToast(data.message || 'Contraseña actualizada.', 'success');
                } else {
                    alert(data.message || 'Contraseña actualizada.');
                }
                form.reset();
            } catch (err) {
                if (typeof window.smartcsetShowToast === 'function') {
                    window.smartcsetShowToast(err.message || 'Error al cambiar contraseña.', 'danger');
                } else {
                    alert(err.message || 'Error al cambiar contraseña.');
                }
            }
        });
    });
})();
