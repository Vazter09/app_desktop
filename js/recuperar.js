/**
 * Lógica de la página de recuperación de clave (src/auth/recuperar.php).
 */
(function () {
    'use strict';

    function toggleMail(ver) {
        var divCorreo = document.getElementById('w_div_correo');
        var txtCorreo = document.getElementById('w_txt_correo');
        if (divCorreo) {
            divCorreo.style.display = ver ? 'block' : 'none';
        }
        if (txtCorreo) {
            txtCorreo.required = ver;
        }
    }

    function togglePass() {
        var passInput = document.getElementById('w_input_pass');
        var icon = document.getElementById('toggleIcon');
        if (!passInput || !icon) {
            return;
        }
        if (passInput.type === 'password') {
            passInput.type = 'text';
            icon.classList.replace('bi-eye', 'bi-eye-slash');
        } else {
            passInput.type = 'password';
            icon.classList.replace('bi-eye-slash', 'bi-eye');
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        var toggleIcon = document.getElementById('toggleIcon');
        if (toggleIcon) {
            toggleIcon.addEventListener('click', togglePass);
        }

        var radios = document.querySelectorAll('input[name="rdo_metodo"]');
        radios.forEach(function (radio) {
            radio.addEventListener('click', function () {
                toggleMail(this.value === 'correo');
            });
        });

        // Bloquear navegación hacia atrás
        history.pushState(null, null, location.href);
        window.onpopstate = function () {
            history.go(1);
        };

        // Confirmación solo si hay cambios sin guardar
        var hasChanges = false;
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
        document.addEventListener('submit', function () {
            hasChanges = false;
        });
    });
})();
