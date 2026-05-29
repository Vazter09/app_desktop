/**
 * SmartCSET — notificaciones con Bootstrap Toast
 */
(function (global) {
    'use strict';

    const ICONS = {
        success: 'bi-check-circle-fill',
        error: 'bi-exclamation-circle-fill',
        warning: 'bi-exclamation-triangle-fill',
        info: 'bi-info-circle-fill'
    };

    const TITLES = {
        success: 'Listo',
        error: 'No se pudo completar',
        warning: 'Atención',
        info: 'Información'
    };

    function getContainer() {
        let el = document.getElementById('toast-container');
        if (!el) {
            el = document.createElement('div');
            el.id = 'toast-container';
            el.className = 'toast-container smart-toast-container position-fixed bottom-0 end-0 p-3';
            el.style.zIndex = '1080';
            document.body.appendChild(el);
        }
        return el;
    }

    function normalizeMessage(message) {
        let text = String(message || '')
            .replace(/\\n/g, '\n')
            .replace(/^\s*:\s*/, '')
            .trim();

        // Quitar bloques técnicos de PostgreSQL si llegaran al cliente.
        text = text.split(/\b(?:DETAIL|DETALLE|HINT|SUGERENCIA|CONTEXT|CONTEXTO)\s*:/i)[0];
        text = text.replace(/^SQLSTATE\[[^\]]+\]:\s*/i, '');
        text = text.replace(/<<[^>]+>>:\s*\d+\s*/g, '');
        text = text.replace(/^ERROR:\s*/i, '');

        return text.trim();
    }

    /**
     * @param {'success'|'error'|'warning'|'info'} type
     * @param {string} title
     * @param {string} message
     * @param {{ delay?: number }} [options]
     */
    function show(type, title, message, options) {
        const body = normalizeMessage(message);
        const heading = (title || TITLES[type] || 'Aviso').trim();

        if (typeof bootstrap === 'undefined' || !bootstrap.Toast) {
            global.alert((heading ? heading + '\n\n' : '') + (body || ''));
            return;
        }

        const delay = (options && options.delay) || (type === 'error' ? 8000 : 5000);
        const icon = ICONS[type] || ICONS.info;
        const safeTitle = escapeHtml(heading);
        const safeMsg = escapeHtml(body);

        const toastEl = document.createElement('div');
        toastEl.className = `toast smart-toast smart-toast--${type} border-0`;
        toastEl.setAttribute('role', 'alert');
        toastEl.setAttribute('aria-live', type === 'error' ? 'assertive' : 'polite');
        toastEl.setAttribute('aria-atomic', 'true');
        toastEl.innerHTML = `
            <div class="smart-toast__inner">
                <span class="smart-toast__icon" aria-hidden="true"><i class="bi ${icon}"></i></span>
                <div class="smart-toast__body">
                    <div class="smart-toast__title">${safeTitle}</div>
                    ${safeMsg ? `<div class="smart-toast__message">${safeMsg.replace(/\n/g, '<br>')}</div>` : ''}
                </div>
                <button type="button" class="btn-close smart-toast__close" data-bs-dismiss="toast" aria-label="Cerrar"></button>
            </div>`;

        getContainer().appendChild(toastEl);
        const instance = bootstrap.Toast.getOrCreateInstance(toastEl, { delay, autohide: true });
        toastEl.addEventListener('hidden.bs.toast', () => toastEl.remove());
        instance.show();
    }

    function escapeHtml(str) {
        return str
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function fromErrorData(errorData) {
        const source = errorData.source || 'UNKNOWN';
        const message = errorData.message || 'No se pudo completar la operación.';
        let type = 'error';
        if (source === 'VALIDATION') type = 'warning';
        if (source === 'NETWORK') type = 'warning';
        const titles = {
            DATABASE: 'No se pudo completar',
            VALIDATION: 'Revise los datos',
            NETWORK: 'Error de conexión',
            SYSTEM: 'Error del sistema'
        };
        show(type, titles[source] || TITLES[type], message);
    }

    function fromSuccessData(successData, extraLine) {
        const message = successData.message || 'Operación completada';
        const cantidad = successData.cantidadGuardada ?? successData.copiados;
        let body = message;
        if (cantidad != null && cantidad > 0) {
            body += `\n(${cantidad} menú${cantidad !== 1 ? 's' : ''})`;
        }
        if (extraLine) body += '\n' + extraLine;
        show('success', 'Listo', body);
    }

    function normalizeFlashType(raw) {
        if (raw === 'danger') return 'error';
        if (['success', 'error', 'warning', 'info'].includes(raw)) return raw;
        return 'success';
    }

    function showFlashFromPage() {
        const node = document.getElementById('page-flash-data');
        if (!node) return;
        const type = normalizeFlashType(node.dataset.type || 'success');
        const title = (node.dataset.title || '').trim();
        const message = (node.dataset.message || '').trim();
        show(type, title || TITLES[type], message);
        node.remove();
    }

    global.SmartToast = {
        show,
        success: (msg, title) => show('success', title || TITLES.success, msg),
        error: (msg, title) => show('error', title || TITLES.error, msg),
        warning: (msg, title) => show('warning', title || TITLES.warning, msg),
        info: (msg, title) => show('info', title || TITLES.info, msg),
        fromErrorData,
        fromSuccessData
    };

    function bootFlashFromPage() {
        if (document.getElementById('page-flash-data')) {
            showFlashFromPage();
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bootFlashFromPage);
    } else {
        bootFlashFromPage();
    }
})(window);
