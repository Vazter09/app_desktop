/**
 * Lógica de la página de login (index.php).
 */
(function () {
    'use strict';

    var loginForm = document.getElementById('loginForm');
    var submitBtn = document.getElementById('loginSubmitBtn');
    var clientError = document.getElementById('loginClientError');
    var passInput = document.getElementById('txt_clave');

    if (!loginForm || !submitBtn) {
        return;
    }

    loginForm.addEventListener('submit', function (e) {
        var pass = passInput ? passInput.value : '';

        if (pass.length < 8) {
            e.preventDefault();
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
    });

    history.pushState(null, null, location.href);
    window.onpopstate = function () {
        history.go(1);
    };
})();
