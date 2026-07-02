/**
 * Prefijo APP_BASE_PATH para URLs absolutas en el cliente.
 */
(function (global) {
    'use strict';

    function basePath() {
        // Inline script puede estar bloqueado por CSP — leer meta tag como fuente primaria
        var meta = document.querySelector('meta[name="smartcset-base-path"]');
        if (meta) {
            return meta.getAttribute('content') || '';
        }
        return typeof global.SMARTCSET_BASE_PATH === 'string' ? global.SMARTCSET_BASE_PATH : '';
    }

    global.smartcsetUrl = function smartcsetUrl(path) {
        const p = path.charAt(0) === '/' ? path : '/' + path;
        const base = basePath();
        return base ? base + p : p;
    };
})(window);
