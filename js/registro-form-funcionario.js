/**
 * Filtrado de áreas por centro (formulario funcionario, módulo registro).
 */
(function () {
    'use strict';

    function filtrarAreasPorCentro() {
        var centro = document.getElementById('id_centro').value;
        var sel = document.getElementById('id_area');
        var prev = sel.value;

        Array.from(sel.options).forEach(function (opt, idx) {
            if (idx === 0) {
                opt.hidden = false;
                return;
            }
            var optCentro = opt.getAttribute('data-centro') || '';
            opt.hidden = centro !== '' && optCentro !== centro;
        });

        if (prev && sel.querySelector('option[value="' + prev + '"]:not([hidden])')) {
            sel.value = prev;
        } else {
            sel.value = '';
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        var centro = document.getElementById('id_centro');
        if (centro) {
            centro.addEventListener('change', filtrarAreasPorCentro);
        }
    });
})();
