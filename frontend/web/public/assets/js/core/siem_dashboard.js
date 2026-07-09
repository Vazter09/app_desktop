/**
 * Auto-refresh del panel de control SIEM vía SmartcsetListado (partial HTML).
 * Mismo patrón de guards que smartcset-presencia.js: evita solapar
 * requests y pausa el polling con la pestaña en background.
 */
(function () {
    'use strict';

    var REFRESH_SEG = 20;
    var inFlight = false;

    function refresh(host) {
        if (inFlight || document.visibilityState === 'hidden') {
            return;
        }
        inFlight = true;
        window.SmartcsetListado.loadIntoHost(host, window.location.href, false)
            .finally(function () {
                inFlight = false;
            });
    }

    document.addEventListener('DOMContentLoaded', function () {
        var host = document.getElementById('siem-panel-host');
        if (!host || !window.SmartcsetListado) {
            return;
        }

        window.setInterval(function () {
            refresh(host);
        }, REFRESH_SEG * 1000);

        document.addEventListener('visibilitychange', function () {
            if (document.visibilityState === 'visible') {
                refresh(host);
            }
        });
    });
})();
