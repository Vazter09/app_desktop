/**
 * Toggle de campos de vehículo en formulario de instructor.
 * Activa placa + tipo solo cuando ind_vehiculo está marcado.
 */
(function () {
    'use strict';

    function syncVehiculoFields(form) {
        var toggle = form.querySelector('#ind_vehiculo');
        var panel = form.querySelector('#vehiculo-fields');
        var placa = form.querySelector('#id_vehiculo');
        var tipo = form.querySelector('#ind_tipovehiculo');
        if (!toggle || !panel || !placa || !tipo) {
            return;
        }

        var on = !!toggle.checked;
        panel.hidden = !on;
        panel.setAttribute('aria-hidden', on ? 'false' : 'true');
        placa.disabled = !on;
        tipo.disabled = !on;
        placa.required = on;
        tipo.required = on;

        if (!on) {
            placa.value = '';
            tipo.value = '';
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        document.querySelectorAll('form[data-registro-tipo="instructor"]').forEach(function (form) {
            var toggle = form.querySelector('#ind_vehiculo');
            if (!toggle) {
                return;
            }

            toggle.addEventListener('change', function () {
                syncVehiculoFields(form);
            });

            form.addEventListener('reset', function () {
                window.setTimeout(function () {
                    syncVehiculoFields(form);
                }, 0);
            });

            var placa = form.querySelector('#id_vehiculo');
            if (placa) {
                placa.addEventListener('input', function () {
                    placa.value = placa.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
                });
            }

            syncVehiculoFields(form);
        });
    });
})();
