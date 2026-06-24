/**
 * Recuperación de clave — router JSON.
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

    function mostrarClavePantalla(clave) {
        var cardBody = document.querySelector('.card-recuperar .card-body');
        if (!cardBody) {
            return;
        }
        cardBody.innerHTML = ''
            + '<div class="text-center p-3 bg-light border rounded">'
            + '<p class="small fw-bold text-muted mb-2">SU NUEVA CLAVE TEMPORAL:</p>'
            + '<div class="pass-container mb-3">'
            + '<input type="password" id="w_input_pass" class="form-control form-control-lg text-center font-monospace" value="'
            + String(clave).replace(/"/g, '&quot;') + '" readonly>'
            + '<i class="bi bi-eye toggle-btn" id="toggleIcon"></i>'
            + '</div>'
            + '<p class="small text-warning mb-0"><i class="bi bi-exclamation-triangle-fill me-1"></i>Copie su clave antes de salir.</p>'
            + '<a href="/index.php" class="btn btn-verde w-100 mt-2">Volver al Login</a>'
            + '</div>';
        var toggleIcon = document.getElementById('toggleIcon');
        if (toggleIcon) {
            toggleIcon.addEventListener('click', togglePass);
        }
        history.pushState(null, null, location.href);
        window.onpopstate = function () {
            history.go(1);
        };
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

        var form = document.getElementById('form-recuperar');
        if (form && typeof SmartcsetAuthRouter !== 'undefined') {
            var hasChanges = false;
            document.addEventListener('input', function (e) {
                if (e.target.closest('#form-recuperar')) {
                    hasChanges = true;
                }
            });
            window.addEventListener('beforeunload', function (e) {
                if (hasChanges) {
                    e.preventDefault();
                    e.returnValue = '';
                }
            });

            form.addEventListener('submit', async function (e) {
                e.preventDefault();
                hasChanges = false;
                var usuario = (form.querySelector('[name="txt_usuario"]') || {}).value || '';
                var metodo = (form.querySelector('[name="rdo_metodo"]:checked') || {}).value || 'correo';
                var correo = (form.querySelector('[name="txt_correo"]') || {}).value || '';

                try {
                    var data = await SmartcsetAuthRouter.recuperar({
                        usuario: usuario,
                        metodo: metodo,
                        correo: correo,
                    });
                    if (data.mostrar_pantalla && data.clave_temporal) {
                        mostrarClavePantalla(data.clave_temporal);
                        return;
                    }
                    if (typeof window.smartcsetShowToast === 'function') {
                        window.smartcsetShowToast(data.message || 'Clave enviada.', 'success');
                    }
                    setTimeout(function () {
                        window.location.href = smartcsetUrl('/index.php');
                    }, 1200);
                } catch (err) {
                    if (typeof window.smartcsetShowToast === 'function') {
                        window.smartcsetShowToast(err.message || 'Error al recuperar.', 'danger');
                    } else {
                        alert(err.message || 'Error al recuperar.');
                    }
                }
            });
        }
    });
})();
