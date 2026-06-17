/**
 * Toggle de credenciales del módulo de registro (admin/personas/config.php).
 */
(function () {
    'use strict';

    var chkModulo = document.getElementById('chk_modulo');
    var wrapCreds = document.getElementById('registro-credenciales-wrap');
    if (!chkModulo) {
        return;
    }

    var sync = function () {
        var on = chkModulo.checked;
        if (wrapCreds) {
            wrapCreds.hidden = !on;
        }
    };

    chkModulo.addEventListener('change', sync);
    sync();
})();
