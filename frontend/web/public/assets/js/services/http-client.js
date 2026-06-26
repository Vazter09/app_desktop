/**
 * Cliente HTTP base para routers SmartCSET.
 */
(function (global) {
    'use strict';

    function resolveBasePath() {
        if (typeof global.smartcsetResolveBasePath === 'function') {
            const fromHelper = global.smartcsetResolveBasePath();
            if (fromHelper) {
                return fromHelper;
            }
        }
        if (typeof global.SMARTCSET_BASE_PATH === 'string' && global.SMARTCSET_BASE_PATH !== '') {
            return global.SMARTCSET_BASE_PATH;
        }
        const meta = document.querySelector('meta[name="smartcset-base-path"]');
        return meta ? (meta.getAttribute('content') || '').trim() : '';
    }

    function resolveAppUrl(url) {
        if (typeof url !== 'string' || !url.startsWith('/')) {
            return url;
        }
        if (typeof global.smartcsetUrl === 'function') {
            const resolved = global.smartcsetUrl(url);
            if (resolved !== url) {
                return resolved;
            }
        }
        const base = resolveBasePath();
        return base ? base + url : url;
    }

    async function request(url, options = {}) {
        url = resolveAppUrl(url);
        const opts = {
            credentials: 'include',
            headers: {
                Accept: 'application/json',
                ...(options.headers || {}),
            },
            ...options,
        };

        if (opts.body && typeof opts.body === 'object' && !(opts.body instanceof FormData)) {
            opts.headers['Content-Type'] = 'application/json';
            opts.body = JSON.stringify(opts.body);
        }

        const response = await fetch(url, opts);
        let payload;
        try {
            payload = await response.json();
        } catch (e) {
            throw new Error('Respuesta no válida del servidor.');
        }

        if (!payload || payload.ok !== true) {
            const msg = (payload && payload.error) ? payload.error : 'No se pudo completar la operación.';
            throw new Error(msg);
        }

        return payload.data ?? {};
    }

    global.SmartcsetHttp = {
        get(url, params = {}) {
            const qs = new URLSearchParams(params).toString();
            const full = qs ? `${url}?${qs}` : url;
            return request(full, { method: 'GET' });
        },
        post(url, body = {}) {
            return request(url, { method: 'POST', body });
        },
    };
})(window);
