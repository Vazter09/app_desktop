/**
 * Prefijo APP_BASE_PATH para URLs absolutas en el cliente.
 * Fuente CSP-safe: meta[name="smartcset-base-path"] (no script inline).
 */
(function (global) {
    'use strict';

    function resolveBasePath() {
        if (typeof global.SMARTCSET_BASE_PATH === 'string' && global.SMARTCSET_BASE_PATH !== '') {
            return global.SMARTCSET_BASE_PATH;
        }
        const meta = document.querySelector('meta[name="smartcset-base-path"]');
        const fromMeta = meta ? (meta.getAttribute('content') || '').trim() : '';
        return fromMeta;
    }

    function prefixPath(path) {
        const p = path.charAt(0) === '/' ? path : '/' + path;
        const base = resolveBasePath();
        return base ? base + p : p;
    }

    global.smartcsetResolveBasePath = resolveBasePath;
    global.smartcsetUrl = function smartcsetUrl(path) {
        return prefixPath(path);
    };
})(window);
