/**
 * Registro de ingresos — portería (captura PDF417, bloqueo ingreso activo).
 * Documentación línea por línea: docs/porteria-codigo-linea-a-linea.md
 */
(function () {
    let ingresosAbort = null;

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

    function resolveIngresoModal() {
        if (window.PorteriaModalHost?.ensureModalOnBody) {
            return window.PorteriaModalHost.ensureModalOnBody('ingresoFormModal');
        }
        return document.getElementById('ingresoFormModal');
    }

    function initIngresos() {
        const PC = window.PorteriaCaptura;
        const PM = window.PorteriaMedios;
        if (!PC) return;

        const formModalEl = resolveIngresoModal();
        if (!formModalEl) return;

        const form = formModalEl.querySelector('#form_ingreso');
        const inputDoc = formModalEl.querySelector('#txt_documento');
        const selTipo = formModalEl.querySelector('#sel_tipo_doc');
        const inputNom = formModalEl.querySelector('#txt_nombres');
        const inputApe = formModalEl.querySelector('#txt_apellidos');
        const inputPuerta = formModalEl.querySelector('#sel_entrada');
        const puertaError = formModalEl.querySelector('#puerta_error');
        const selTipoPersona = formModalEl.querySelector('#sel_tipo_persona');
        const badge = formModalEl.querySelector('#badge_persona');
        const bloqueoMsg = formModalEl.querySelector('#ingreso_bloqueado_msg');
        const btnSubmit = formModalEl.querySelector('#btn_registrar_ingreso');
        const hidCaptura = formModalEl.querySelector('#hid_captura_raw');
        const hidMetodo = formModalEl.querySelector('#hid_metodo_aut');

        if (!inputDoc || !form) return;

        if (ingresosAbort) {
            ingresosAbort.abort();
        }
        ingresosAbort = new AbortController();
        const { signal } = ingresosAbort;

        let timer = null;
        let puedeIngresar = true;
        let consultaEnCurso = false;

        let formModal = null;
        if (formModalEl && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            formModal = bootstrap.Modal.getOrCreateInstance(formModalEl);
        }

        const btnAbrirModal = document.getElementById('btn_abrir_ingreso_modal');
        if (btnAbrirModal) {
            btnAbrirModal.addEventListener('click', () => {
                if (window.PorteriaModalHost?.showModal) {
                    window.PorteriaModalHost.showModal('ingresoFormModal');
                } else if (formModal) {
                    formModal.show();
                }
                setTimeout(() => inputDoc.focus(), 200);
            }, { signal });
        }

        function setBadge(state, text) {
            if (!badge) return;
            badge.className = 'badge rounded-pill';
            badge.classList.add('d-none');
            if (state === 'hide') return;
            badge.classList.remove('d-none');
            badge.textContent = text;
            if (state === 'known') badge.classList.add('ingresos-badge-known');
            if (state === 'new') badge.classList.add('ingresos-badge-new');
            if (state === 'loading') badge.classList.add('ingresos-badge-loading');
            if (state === 'blocked') badge.classList.add('ingresos-badge-blocked');
        }

        function setBloqueoMsg(visible, html) {
            if (!bloqueoMsg) return;
            if (!visible) {
                bloqueoMsg.classList.add('d-none');
                bloqueoMsg.textContent = '';
                return;
            }
            bloqueoMsg.classList.remove('d-none');
            bloqueoMsg.innerHTML = html;
        }

        function actualizarSubmit() {
            const puertaOk = Boolean(inputPuerta?.value);
            const docOk = inputDoc.value.replace(/\D/g, '').length >= 5;
            if (btnSubmit) {
                btnSubmit.disabled = !puertaOk || !docOk || !puedeIngresar || consultaEnCurso;
            }
        }

        function liberarNombres() {
            inputNom.readOnly = false;
            inputApe.readOnly = false;
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
            if (parsed.nombres) inputNom.value = parsed.nombres;
            if (parsed.apellidos) inputApe.value = parsed.apellidos;
        }

        function mostrarIngresoAbierto(ingreso) {
            puedeIngresar = false;
            const hora = PorteriaCaptura.formatDbTime(ingreso.fec_ingreso);
            setBadge('blocked', `Ingreso activo #${ingreso.id_ingreso}`);
            setBloqueoMsg(
                true,
                `Esta persona ya ingresó (${hora}, puerta ${ingreso.id_entrada ?? ingreso.id_entrada_centro}). `
                + 'Registre la <strong>salida</strong> antes de un nuevo ingreso.'
            );
            actualizarSubmit();
        }

        async function consultarAcceso(inmediato) {
            const documento = inputDoc.value.replace(/\D/g, '');
            if (documento.length < 5) {
                puedeIngresar = true;
                liberarNombres();
                setBadge('hide');
                setBloqueoMsg(false);
                actualizarSubmit();
                return;
            }

            if (typeof SmartcsetIngresoRouter === 'undefined') {
                showToast('danger', 'Error', 'No se cargó el cliente de portería. Recargue la página.');
                return;
            }

            consultaEnCurso = true;
            actualizarSubmit();
            setBadge('loading', 'Buscando…');
            setBloqueoMsg(false);

            try {
                const data = await SmartcsetIngresoRouter.consultar(documento, selTipo.value);

                puedeIngresar = Boolean(data.puede_ingresar);

                if (data.ingreso_abierto) {
                    mostrarIngresoAbierto(data.ingreso_abierto);
                } else {
                    setBloqueoMsg(false);
                }

                if (data.persona) {
                    const tipoDocBd = data.persona.tipo_doc || data.persona.id_tipo_docum;
                    if (tipoDocBd && selTipo && selTipo.value !== tipoDocBd) {
                        const opt = Array.from(selTipo.options).find((o) => o.value === tipoDocBd);
                        if (opt) selTipo.value = tipoDocBd;
                    }
                    inputNom.value = data.persona.nombres || data.persona.nom_persona || '';
                    inputApe.value = data.persona.apellidos || data.persona.ape_persona || '';
                    inputNom.readOnly = true;
                    inputApe.readOnly = true;
                    const idTipoPersona = data.persona.tipo_persona ?? data.persona.id_tipo_persona;
                    if (selTipoPersona && idTipoPersona) {
                        selTipoPersona.value = String(idTipoPersona);
                    }
                    const tipoNom = data.persona.nom_tipo_persona || 'registrada';
                    if (puedeIngresar) {
                        setBadge('known', `Persona ${tipoNom}`);
                    }
                } else {
                    liberarNombres();
                    inputNom.value = '';
                    inputApe.value = '';
                    if (puedeIngresar) {
                        setBadge('new', 'Persona nueva — indique el tipo');
                    }
                }
            } catch (err) {
                puedeIngresar = true;
                setBadge('hide');
                showToast('danger', 'Consulta', err.message || 'No se pudo consultar el documento.');
            } finally {
                consultaEnCurso = false;
                actualizarSubmit();
            }

            if (!inmediato) {
                /* noop — flag reservado */
            }
        }

        function onCaptura(parsed, esEscaneo) {
            aplicarCaptura(parsed);
            clearTimeout(timer);
            if (esEscaneo || parsed.origen === 'pdf417') {
                consultarAcceso(true);
            } else {
                timer = setTimeout(() => consultarAcceso(false), 400);
            }
        }

        if (!inputDoc.dataset.capturaEnlazada) {
            inputDoc.dataset.capturaEnlazada = '1';
            PC.enlazarCapturaDocumento(inputDoc, { onCaptura });
        }

        document.querySelectorAll('#ingresoFormModal .ing-puerta').forEach((btn) => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('#ingresoFormModal .ing-puerta').forEach((b) => {
                    b.classList.toggle('is-selected', b === btn);
                });
                if (inputPuerta) inputPuerta.value = btn.dataset.puerta;
                if (puertaError) puertaError.style.display = 'none';
                actualizarSubmit();
            }, { signal });
        });

        inputDoc.addEventListener('input', () => {
            if (!inputDoc.value.includes('@')) {
                if (hidCaptura) hidCaptura.value = '';
                if (hidMetodo) hidMetodo.value = String(PC.METODO_MANUAL);
                liberarNombres();
            }
            clearTimeout(timer);
            timer = setTimeout(() => consultarAcceso(false), 400);
        }, { signal });

        selTipo?.addEventListener('change', () => {
            liberarNombres();
            consultarAcceso(true);
        }, { signal });

        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            if (!inputPuerta?.value) {
                if (puertaError) puertaError.style.display = 'block';
                formModalEl.querySelector('#puertas_grid')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                return;
            }
            if (!puedeIngresar) {
                setBadge('blocked', 'Ingreso bloqueado');
                return;
            }
            inputNom.readOnly = false;
            inputApe.readOnly = false;

            const payload = {
                documento: inputDoc.value.replace(/\D/g, ''),
                tipo_doc: selTipo?.value || 'CC',
                nombres: inputNom.value,
                apellidos: inputApe.value,
                id_entrada: Number(inputPuerta.value),
                tipo_persona: Number(selTipoPersona?.value || 1),
                metodo_aut: Number(hidMetodo?.value || 1),
                observaciones: formModalEl.querySelector('#txt_observaciones')?.value || '',
                foto_base64: formModalEl.querySelector('#hid_foto_data')?.value || '',
            };

            if (btnSubmit) btnSubmit.disabled = true;
            try {
                const result = await SmartcsetIngresoRouter.registrar(payload);
                if (formModal) formModal.hide();
                window.location.href = window.location.pathname + '?ok=' + encodeURIComponent(result.id_ingreso);
            } catch (err) {
                showToast('danger', 'No se pudo completar', err.message);
                if (btnSubmit) btnSubmit.disabled = false;
            }
        }, { signal });

        formModalEl.addEventListener('shown.bs.modal', () => {
            const doc = inputDoc.value.replace(/\D/g, '');
            if (doc.length >= 5 && !inputNom.value.trim() && !consultaEnCurso) {
                consultarAcceso(true);
            }
            inputDoc.focus();
        }, { signal });

        if (PM) {
            PM.init({
                form,
                inputDoc,
                resetEscaner: form.dataset.ptReset === '1',
            });
        }

        actualizarSubmit();

        if (inputPuerta?.value) {
            const btn = formModalEl.querySelector(`.ing-puerta[data-puerta="${inputPuerta.value}"]`);
            if (btn) btn.classList.add('is-selected');
        }
    }

    if (typeof window.smartcsetOnPageReady === 'function') {
        window.smartcsetOnPageReady(initIngresos);
    } else {
        document.addEventListener('DOMContentLoaded', initIngresos);
    }
})();
