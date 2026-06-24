/**
 * SmartCSET — cargue de reportes SENA.
 * Envía el archivo del reporte por fetch al router y muestra el resultado.
 * Usa delegación a nivel documento para seguir funcionando tras los swaps de
 * navegación parcial (smartcset-spa.js).
 */
(function () {
    'use strict';

    function setMsg(el, html, type) {
        if (!el) {
            return;
        }
        const cls = type === 'success' ? 'text-success' : type === 'danger' ? 'text-danger' : 'text-muted';
        const icon = type === 'success' ? 'check-circle' : type === 'danger' ? 'exclamation-triangle' : 'hourglass-split';
        el.innerHTML = '<span class="' + cls + '"><i class="bi bi-' + icon + ' me-1"></i>' + html + '</span>';
    }

    document.addEventListener('submit', async function (e) {
        const form = e.target.closest('form[data-cargue-form]');
        if (!form) {
            return;
        }
        e.preventDefault();

        const fileInput = form.querySelector('input[type="file"]');
        const result = form.parentElement.querySelector('.cargue-result');
        const btn = form.querySelector('button[type="submit"]');

        if (!fileInput || !fileInput.files.length) {
            setMsg(result, 'Selecciona un archivo primero.', 'danger');
            return;
        }

        const fd = new FormData(form);
        fd.set('reporte', form.getAttribute('data-reporte') || '');

        if (btn) {
            btn.disabled = true;
        }
        setMsg(result, 'Subiendo archivo…', 'muted');

        try {
            const res = await fetch(form.action, {
                method: 'POST',
                body: fd,
                credentials: 'same-origin',
                headers: { 'X-Requested-With': 'fetch' },
            });
            let data = {};
            try {
                data = await res.json();
            } catch (parseErr) {
                data = {};
            }
            if (res.ok && data && data.ok) {
                setMsg(result, data.message || 'Archivo cargado correctamente.', 'success');
                form.reset();
            } else {
                setMsg(result, (data && data.error) || 'Error al cargar (HTTP ' + res.status + ').', 'danger');
            }
        } catch (err) {
            setMsg(result, 'Error de red al subir el archivo.', 'danger');
        } finally {
            if (btn) {
                btn.disabled = false;
            }
        }
    });
})();
