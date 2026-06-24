/**
 * Login — validación cliente + router JSON.
 */
(function () {
    'use strict';

    const loginForm = document.getElementById('loginForm');
    const submitBtn = document.getElementById('loginSubmitBtn');
    const clientError = document.getElementById('loginClientError');
    const passInput = document.getElementById('txt_clave');
    const userInput = document.getElementById('txt_usuario');

    if (!loginForm || !submitBtn) {
        return;
    }

    loginForm.addEventListener('submit', async function (e) {
        e.preventDefault();

        const pass = passInput ? passInput.value : '';
        const user = userInput ? userInput.value.trim() : '';

        if (pass.length < 8) {
            if (clientError) {
                clientError.textContent = 'La contraseña debe tener al menos 8 caracteres.';
                clientError.classList.add('is-visible');
            }
            return;
        }

        if (clientError) {
            clientError.classList.remove('is-visible');
        }

        submitBtn.disabled = true;
        submitBtn.textContent = 'Verificando…';

        try {
            const data = await SmartcsetAuthRouter.login(user, pass);
            window.location.href = data.redirect || smartcsetUrl('/pages/menu/menu_principal.php');
        } catch (err) {
            if (clientError) {
                clientError.textContent = err.message || 'No se pudo iniciar sesión.';
                clientError.classList.add('is-visible');
            }
            submitBtn.disabled = false;
            submitBtn.textContent = 'INGRESAR AL SISTEMA';
        }
    });

    history.pushState(null, null, location.href);
    window.onpopstate = function () {
        history.go(1);
    };
})();
