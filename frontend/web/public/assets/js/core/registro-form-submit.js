/**
 * Envío de formularios del módulo registro vía router JSON.
 */
(function () {
    'use strict';

    function showFormAlert(container, message, isError) {
        var existing = container.querySelector('.registro-form-alert');
        if (existing) {
            existing.remove();
        }
        var div = document.createElement('div');
        div.className = 'registro-form-alert alert ' + (isError ? 'alert-error' : 'alert-success');
        div.textContent = (isError ? '⚠ ' : '✔ ') + message;
        var formContainer = container.querySelector('.form-container') || container;
        formContainer.insertBefore(div, formContainer.firstChild);
        div.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    document.addEventListener('DOMContentLoaded', function () {
        if (typeof SmartcsetRegistroRouter === 'undefined') {
            return;
        }

        document.querySelectorAll('form[data-registro-tipo]').forEach(function (form) {
            form.addEventListener('submit', async function (e) {
                e.preventDefault();
                var tipo = form.getAttribute('data-registro-tipo') || '';
                var fd = new FormData(form);
                fd.set('tipo', tipo);

                var btn = form.querySelector('[type="submit"]');
                if (btn) {
                    btn.disabled = true;
                }

                try {
                    var data = await SmartcsetRegistroRouter.guardar(fd);
                    showFormAlert(document, data.message || 'Guardado correctamente.', false);
                    if (typeof form.reset === 'function' && tipo !== 'aprendiz') {
                        form.reset();
                    }
                } catch (err) {
                    showFormAlert(document, err.message || 'Error al guardar.', true);
                } finally {
                    if (btn) {
                        btn.disabled = false;
                    }
                }
            });
        });
    });
})();
