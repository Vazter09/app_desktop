/**
 * Búsqueda automática de aprendiz por documento y carga de ciudades (módulo registro).
 */
(function () {
    'use strict';

    var debounceTimer = null;
    var lastFetchedKey = '';

    function cargarCiudades(idDpto, selectedCiudad) {
        var sel = document.getElementById('id_ciudad_reside');
        if (!sel) {
            return Promise.resolve();
        }

        if (!idDpto) {
            sel.innerHTML = '<option value="">— Seleccione departamento —</option>';
            return Promise.resolve();
        }

        sel.innerHTML = '<option value="">Cargando...</option>';

        return fetch('../ajax_ciudades.php?id_dpto=' + encodeURIComponent(idDpto))
            .then(function (r) {
                return r.json();
            })
            .then(function (data) {
                sel.innerHTML = '<option value="">— Seleccione ciudad —</option>';
                if (!Array.isArray(data)) {
                    return;
                }
                data.forEach(function (c) {
                    var opt = document.createElement('option');
                    opt.value = String(c.id_ciudad);
                    opt.textContent = c.nom_ciudad;
                    sel.appendChild(opt);
                });
                if (selectedCiudad) {
                    sel.value = String(selectedCiudad);
                }
            })
            .catch(function () {
                sel.innerHTML = '<option value="">Error al cargar</option>';
            });
    }

    window.cargarCiudades = function (idDpto) {
        return cargarCiudades(idDpto, '');
    };

    function showHint(message, tone) {
        var field = document.getElementById('id_persona');
        if (!field) {
            return;
        }

        var host = field.closest('.field-group');
        if (!host) {
            return;
        }

        var el = document.getElementById('registro-aprendiz-hint');
        if (!el) {
            el = document.createElement('p');
            el.id = 'registro-aprendiz-hint';
            el.className = 'registro-aprendiz-hint';
            el.setAttribute('role', 'status');
            el.setAttribute('aria-live', 'polite');
            host.appendChild(el);
        }

        if (!message) {
            el.textContent = '';
            el.className = 'registro-aprendiz-hint';
            return;
        }

        el.textContent = message;
        el.className = 'registro-aprendiz-hint registro-aprendiz-hint--' + (tone || 'info');
    }

    function setFieldValue(id, value) {
        var el = document.getElementById(id);
        if (!el) {
            return;
        }

        if (el.type === 'checkbox') {
            el.checked = !!value;
            return;
        }

        el.value = value == null ? '' : String(value);
    }

    function populateForm(data) {
        var personaFields = [
            'id_tipo_docum',
            'nom_persona',
            'ape_persona',
            'mail_persona',
            'fec_nacimiento',
            'ind_genero',
            'id_nivel_estudio',
            'id_profesion',
            'dir_ciudad_reside',
            'tel_persona_fijo',
            'tel_persona_movil',
            'nom_contacto_emergencias',
            'tel_contacto_emergencias',
            'ind_etdo_formacion',
            'tel_alterno',
            'tel_sede',
            'ext_sede',
            'tel_padre_fijo',
            'tel_padre_movil',
            'val_mail_institucional',
            'id_ficha'
        ];

        personaFields.forEach(function (name) {
            if (name === 'ind_envio_correo') {
                return;
            }
            setFieldValue(name, data[name]);
        });

        setFieldValue('ind_envio_correo', data.ind_envio_correo);

        var dpto = data.id_dpto_reside || '';
        setFieldValue('id_dpto_reside', dpto);

        return cargarCiudades(dpto, data.id_ciudad_reside || '');
    }

    function buildFetchKey(doc, tipoDoc) {
        return doc + '|' + (tipoDoc || '');
    }

    function buscarAprendiz() {
        var docInput = document.getElementById('id_persona');
        if (!docInput) {
            return;
        }

        var doc = (docInput.value || '').replace(/\D/g, '');
        if (doc.length < 6) {
            lastFetchedKey = '';
            showHint('');
            return;
        }

        var tipoSelect = document.getElementById('id_tipo_docum');
        var tipoDoc = tipoSelect ? tipoSelect.value : '';
        var fetchKey = buildFetchKey(doc, tipoDoc);

        if (fetchKey === lastFetchedKey) {
            return;
        }

        var url = '../ajax_buscar_aprendiz.php?id_persona=' + encodeURIComponent(doc);
        if (tipoDoc) {
            url += '&id_tipo_docum=' + encodeURIComponent(tipoDoc);
        }

        showHint('Consultando datos…', 'info');

        fetch(url)
            .then(function (r) {
                return r.json();
            })
            .then(function (payload) {
                var status = payload && payload.status ? payload.status : 'error';

                if (status === 'not_found' || status === 'invalid') {
                    lastFetchedKey = '';
                    showHint(payload.message || 'No se encontraron datos.', 'warn');
                    return;
                }

                if (status === 'error') {
                    lastFetchedKey = '';
                    showHint(payload.message || 'Error al consultar.', 'warn');
                    return;
                }

                lastFetchedKey = fetchKey;

                if (payload.data) {
                    populateForm(payload.data).then(function () {
                        if (status === 'partial') {
                            showHint(payload.message || 'Datos parciales cargados.', 'warn');
                        } else {
                            showHint('Datos cargados desde el sistema.', 'ok');
                        }
                    });
                    return;
                }

                showHint('');
            })
            .catch(function () {
                lastFetchedKey = '';
                showHint('No se pudo consultar el documento.', 'warn');
            });
    }

    function scheduleBuscar() {
        if (debounceTimer) {
            clearTimeout(debounceTimer);
        }
        debounceTimer = setTimeout(buscarAprendiz, 450);
    }

    function init() {
        var form = document.getElementById('registro-form-aprendiz');
        if (!form) {
            return;
        }

        var docInput = document.getElementById('id_persona');
        var tipoSelect = document.getElementById('id_tipo_docum');

        if (docInput) {
            docInput.addEventListener('input', scheduleBuscar);
            docInput.addEventListener('blur', buscarAprendiz);
        }

        if (tipoSelect) {
            tipoSelect.addEventListener('change', function () {
                lastFetchedKey = '';
                buscarAprendiz();
            });
        }

        form.addEventListener('reset', function () {
            lastFetchedKey = '';
            showHint('');
            cargarCiudades('', '');
        });

        var dptoSelect = document.getElementById('id_dpto_reside');
        if (dptoSelect) {
            dptoSelect.addEventListener('change', function () {
                cargarCiudades(this.value, '');
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
