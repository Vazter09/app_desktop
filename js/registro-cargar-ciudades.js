/**
 * Carga de ciudades por departamento (formularios de registro).
 */
(function () {
    'use strict';

    function cargarCiudades(idDpto) {
        var sel = document.getElementById('id_ciudad_reside');
        if (!sel) {
            return;
        }

        if (!idDpto) {
            sel.innerHTML = '<option value="">— Seleccione departamento —</option>';
            return;
        }

        sel.innerHTML = '<option value="">Cargando...</option>';

        fetch('../ajax_ciudades.php?id_dpto=' + encodeURIComponent(idDpto))
            .then(function (r) { return r.json(); })
            .then(function (data) {
                sel.innerHTML = '<option value="">— Seleccione ciudad —</option>';
                if (!Array.isArray(data)) {
                    return;
                }
                data.forEach(function (c) {
                    var opt = document.createElement('option');
                    opt.value = c.id_ciudad;
                    opt.textContent = c.nom_ciudad;
                    sel.appendChild(opt);
                });
            })
            .catch(function () {
                sel.innerHTML = '<option value="">Error al cargar</option>';
            });
    }

    window.cargarCiudades = cargarCiudades;

    document.addEventListener('DOMContentLoaded', function () {
        var sel = document.getElementById('id_dpto_reside');
        if (sel) {
            sel.addEventListener('change', function () {
                cargarCiudades(this.value);
            });
        }
    });
})();
