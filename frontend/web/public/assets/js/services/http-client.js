/**
 * Cliente HTTP base para routers SmartCSET.
 */
(function (global) {
    'use strict';

    async function request(url, options = {}) {
        if (typeof url === 'string' && url.startsWith('/') && typeof global.smartcsetUrl === 'function') {
            url = global.smartcsetUrl(url);
        }
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
