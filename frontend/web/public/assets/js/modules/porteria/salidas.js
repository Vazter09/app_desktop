/**
 * Registro de salidas — portería (misma línea que ingreso: PDF417, consulta, modos)
 */
(function () {
    function showToast(tipo, titulo, mensaje) {
        const toastTipo = tipo === 'danger' ? 'error' : tipo;
        if (window.SmartToast && typeof window.SmartToast.show === 'function') {
            window.SmartToast.show(toastTipo, titulo, mensaje);
            return;
        }
        if (window.SmartcsetToast && typeof window.SmartcsetToast.show === 'function') {
            window.SmartcsetToast.show(tipo, titulo, mensaje);
            return;
        }
        alert(mensaje);
    }

    function initSalidas() {
        const PC = window.PorteriaCaptura;
        const PM = window.PorteriaMedios;
        if (!PC) return;

        const inputDoc = document.getElementById('txt_documento');
        const selTipo = document.getElementById('sel_tipo_doc');
        const inputNom = document.getElementById('txt_nombres');
        const inputApe = document.getElementById('txt_apellidos');
        const inputPuerta = document.getElementById('sel_entrada');
        const puertaError = document.getElementById('puerta_error');
        const selTipoPersona = document.getElementById('sel_tipo_persona');
        const badge = document.getElementById('badge_persona');
        const avisoMsg = document.getElementById('salida_aviso_msg');
        const btnSubmit = document.getElementById('btn_registrar_salida');
        const hidIngreso = document.getElementById('hid_id_ingreso');
        const hidCaptura = document.getElementById('hid_captura_raw');
        const hidMetodo = document.getElementById('hid_metodo_aut');
        const form = document.getElementById('form_salida');

        if (!inputDoc || !form || form.dataset.porteriaBound === '1') return;
        form.dataset.porteriaBound = '1';

        let timer = null;
        let puedeSalir = false;
        let consultaEnCurso = false;

        const formModalEl = document.getElementById('salidaFormModal');
        let formModal = null;
        if (formModalEl && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            formModal = bootstrap.Modal.getOrCreateInstance(formModalEl);
        }

        const btnAbrirModal = document.getElementById('btn_abrir_salida_modal');
        if (btnAbrirModal && !btnAbrirModal.dataset.porteriaModalBound) {
            btnAbrirModal.dataset.porteriaModalBound = '1';
            btnAbrirModal.addEventListener('click', () => {
                if (window.PorteriaModalHost?.showModal) {
                    window.PorteriaModalHost.showModal('salidaFormModal');
                } else if (formModal) {
                    formModal.show();
                }
                setTimeout(() => inputDoc.focus(), 200);
            });
        }

        function setBadge(state, text) {
            if (!badge) return;
            badge.className = 'badge rounded-pill';
            badge.classList.add('d-none');
            if (state === 'hide') return;
            badge.classList.remove('d-none');
            badge.textContent = text;
            if (state === 'ok') badge.classList.add('ingresos-badge-known');
            if (state === 'known') badge.classList.add('ingresos-badge-known');
            if (state === 'warn') badge.classList.add('ingresos-badge-blocked');
            if (state === 'error') badge.classList.add('ingresos-badge-blocked');
            if (state === 'loading') badge.classList.add('ingresos-badge-loading');
        }

        function setAvisoMsg(visible, html) {
            if (!avisoMsg) return;
            if (!visible) {
                avisoMsg.classList.add('d-none');
                avisoMsg.textContent = '';
                return;
            }
            avisoMsg.classList.remove('d-none');
            avisoMsg.innerHTML = html;
        }

        function actualizarSubmit() {
            const puertaOk = Boolean(inputPuerta?.value);
            const docOk = inputDoc.value.replace(/\D/g, '').length >= 5;
            if (btnSubmit) {
                btnSubmit.disabled = !puertaOk || !docOk || !puedeSalir || consultaEnCurso;
            }
        }

        function limpiarIngreso() {
            if (hidIngreso) hidIngreso.value = '';
            puedeSalir = false;
            actualizarSubmit();
        }

        function mostrarIngreso(row) {
            if (inputNom) inputNom.value = row.nombres || row.nom_persona || '';
            if (inputApe) inputApe.value = row.apellidos || row.ape_persona || '';
            const idTipo = row.tipo_persona ?? row.id_tipo_persona;
            if (selTipoPersona && idTipo) {
                selTipoPersona.value = String(idTipo);
            }
            const tipoDocBd = row.tipo_doc || row.id_tipo_docum;
            if (tipoDocBd && selTipo) {
                const opt = Array.from(selTipo.options).find((o) => o.value === tipoDocBd);
                if (opt) selTipo.value = tipoDocBd;
            }

            if (hidIngreso) hidIngreso.value = row.id_ingreso;
            puedeSalir = true;
            setAvisoMsg(false);
            setBadge('ok', `Ingreso activo #${row.id_ingreso}`);
            actualizarSubmit();
        }

        function aplicarCaptura(parsed) {
            if (parsed.tipo_doc && selTipo) {
                const opt = Array.from(selTipo.options).find((o) => o.value === parsed.tipo_doc);
                if (opt) selTipo.value = parsed.tipo_doc;
            }
            if (parsed.documento) {
                inputDoc.value = parsed.documento;
            }
            if (hidCaptura) {
                hidCaptura.value = parsed.origen === 'pdf417' ? parsed.captura_raw : '';
            }
            if (hidMetodo) {
                hidMetodo.value = String(PC.metodoAutDesdeOrigen(parsed.origen));
            }
            if (parsed.nombres && inputNom) inputNom.value = parsed.nombres;
            if (parsed.apellidos && inputApe) inputApe.value = parsed.apellidos;
        }

        function mostrarSinIngresoActivo(persona) {
            puedeSalir = false;
            limpiarIngreso();
            if (inputNom) inputNom.value = '';
            if (inputApe) inputApe.value = '';
            if (persona) {
                const tipoNom = persona.nom_tipo_persona || 'registrada';
                setBadge('warn', `Sin ingreso activo — ${tipoNom}`);
                setAvisoMsg(
                    true,
                    'Esta persona no tiene ingreso abierto. Registre primero el <strong>ingreso</strong> en portería.'
                );
            } else {
                setBadge('warn', 'Sin ingreso activo');
                setAvisoMsg(
                    true,
                    'No hay ingreso abierto para este documento. Si es visitante nuevo, regístrelo en <strong>Registro de ingreso</strong>.'
                );
            }
            actualizarSubmit();
        }

        async function consultarAcceso() {
            const documento = inputDoc.value.replace(/\D/g, '');
            if (documento.length < 5) {
                limpiarIngreso();
                setBadge('hide');
                setAvisoMsg(false);
                if (inputNom) inputNom.value = '';
                if (inputApe) inputApe.value = '';
                actualizarSubmit();
                return;
            }

            if (typeof SmartcsetSalidaRouter === 'undefined') {
                showToast('danger', 'Error', 'No se cargó el cliente de portería. Recargue la página.');
                return;
            }

            consultaEnCurso = true;
            actualizarSubmit();
            setBadge('loading', 'Buscando…');
            setAvisoMsg(false);
            limpiarIngreso();

            try {
                const data = await SmartcsetSalidaRouter.consultar(documento, selTipo.value);

                puedeSalir = Boolean(data.puede_salir);

                if (data.ingreso_abierto) {
                    mostrarIngreso(data.ingreso_abierto);
                } else {
                    mostrarSinIngresoActivo(data.persona);
                }
            } catch (err) {
                puedeSalir = false;
                setBadge('error', 'Error de conexión');
                showToast('danger', 'Consulta', err.message || 'No se pudo consultar el documento.');
            } finally {
                consultaEnCurso = false;
                actualizarSubmit();
            }
        }

        function onCaptura(parsed, esEscaneo) {
            aplicarCaptura(parsed);
            clearTimeout(timer);
            if (esEscaneo || parsed.origen === 'pdf417') {
                consultarAcceso();
            } else {
                timer = setTimeout(consultarAcceso, 400);
            }
        }

        PC.enlazarCapturaDocumento(inputDoc, { onCaptura });

        document.querySelectorAll('.ing-puerta').forEach((btn) => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.ing-puerta').forEach((b) => {
                    b.classList.toggle('is-selected', b === btn);
                });
                if (inputPuerta) inputPuerta.value = btn.dataset.puerta;
                if (puertaError) puertaError.style.display = 'none';
                actualizarSubmit();
            });
        });

        inputDoc.addEventListener('input', () => {
            if (!inputDoc.value.includes('@')) {
                if (hidCaptura) hidCaptura.value = '';
                if (hidMetodo) hidMetodo.value = String(PC.METODO_MANUAL);
            }
            clearTimeout(timer);
            timer = setTimeout(consultarAcceso, 400);
        });

        selTipo?.addEventListener('change', consultarAcceso);

        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            if (!inputPuerta?.value) {
                if (puertaError) puertaError.style.display = 'block';
                document.getElementById('puertas_grid')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                return;
            }
            if (!puedeSalir || !hidIngreso?.value) {
                setBadge('warn', 'Debe existir un ingreso activo');
                setAvisoMsg(true, 'Confirme el documento: solo se puede registrar salida con un ingreso abierto.');
                return;
            }

            const payload = {
                documento: inputDoc.value.replace(/\D/g, ''),
                tipo_doc: selTipo?.value || 'CC',
                metodo_aut: Number(hidMetodo?.value || 1),
                observaciones: document.getElementById('txt_observaciones')?.value || '',
                foto_base64: document.getElementById('hid_foto_data')?.value || '',
                id_entrada: Number(inputPuerta?.value || 0),
            };

            if (btnSubmit) btnSubmit.disabled = true;
            try {
                const result = await SmartcsetSalidaRouter.registrar(payload);
                if (formModal) formModal.hide();
                const id = result.id_ingreso || hidIngreso.value;
                window.location.href = window.location.pathname + '?ok=' + encodeURIComponent(id);
            } catch (err) {
                showToast('danger', 'No se pudo completar', err.message);
                if (btnSubmit) btnSubmit.disabled = false;
            }
        });

        if (PM) {
            PM.init({
                form,
                inputDoc,
                resetEscaner: form.dataset.ptReset === '1',
            });
        }

        actualizarSubmit();

        if (inputPuerta?.value) {
            const btn = document.querySelector(`.ing-puerta[data-puerta="${inputPuerta.value}"]`);
            if (btn) btn.classList.add('is-selected');
        }
    }

    if (typeof window.smartcsetOnPageReady === 'function') {
        window.smartcsetOnPageReady(initSalidas);
    } else {
        document.addEventListener('DOMContentLoaded', initSalidas);
    }
})();
