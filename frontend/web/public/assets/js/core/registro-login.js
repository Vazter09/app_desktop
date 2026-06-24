/**
 * Login standalone del módulo de registro.
 */
(function () {
    'use strict';

    document.addEventListener('DOMContentLoaded', function () {
        const form = document.getElementById('form-registro-login');
        if (!form || typeof SmartcsetRegistroRouter === 'undefined') {
            return;
        }

        const errorBox = document.getElementById('registro-login-error');

        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            const usuario = (form.querySelector('[name="usuario"]') || {}).value || '';
            const clave = (form.querySelector('[name="clave"]') || {}).value || '';

            if (errorBox) {
                errorBox.style.display = 'none';
                errorBox.textContent = '';
            }

            try {
                const data = await SmartcsetRegistroRouter.login(usuario, clave);
                window.location.href = data.redirect || smartcsetUrl('/pages/modulos/registro/index.php');
            } catch (err) {
            if (errorBox) {
                errorBox.style.display = 'block';
                const textEl = document.getElementById('registro-login-error-text');
                if (textEl) {
                    textEl.textContent = err.message || 'Credenciales inválidas.';
                }
            }
            }
        });
    });
})();
