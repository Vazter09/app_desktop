/**
 * SmartCSET — heartbeat de presencia (ult_actividad en tab_sesiones).
 */
(function () {
    'use strict';

    const cfg = document.getElementById('smartcset-sesion-presencia');
    if (!cfg) {
        return;
    }

    const url = cfg.getAttribute('data-heartbeat-url');
    if (!url) {
        return;
    }

    const intervalSec = Math.max(
        15,
        parseInt(cfg.getAttribute('data-heartbeat-seg') || '60', 10) || 60
    );

    let inFlight = false;

    function resolverMenuId() {
        const meta = document.querySelector('meta[name="smartcset-active-menu-id"]');
        if (meta && meta.getAttribute('content')) {
            return meta.getAttribute('content');
        }
        return cfg.getAttribute('data-active-menu-id') || '';
    }

    function ping() {
        if (inFlight || document.visibilityState === 'hidden') {
            return;
        }

        inFlight = true;
        const body = new FormData();
        body.append('ult_ruta', window.location.pathname || '');
        const menuId = resolverMenuId();
        if (menuId) {
            body.append('ult_menu_id', menuId);
        }

        fetch(url, {
            method: 'POST',
            body: body,
            credentials: 'same-origin',
            headers: { Accept: 'application/json' }
        })
            .then(function (res) {
                if (!res.ok) {
                    return null;
                }
                return res.json();
            })
            .catch(function () {
                return null;
            })
            .finally(function () {
                inFlight = false;
            });
    }

    ping();
    window.setInterval(ping, intervalSec * 1000);

    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'visible') {
            ping();
        }
    });
})();
