/**
 * Registro de salidas — portería (misma línea que ingreso: PDF417, consulta, modos)
 */
document.addEventListener('DOMContentLoaded', () => {
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

    if (!inputDoc || !form) return;

    let timer = null;
    let puedeSalir = false;
    let consultaEnCurso = false;

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
        const nom = `${row.nom_persona || ''} ${row.ape_persona || ''}`.trim();

        if (inputNom) inputNom.value = row.nom_persona || '';
        if (inputApe) inputApe.value = row.ape_persona || '';
        if (selTipoPersona && row.id_tipo_persona) {
            selTipoPersona.value = String(row.id_tipo_persona);
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

        consultaEnCurso = true;
        actualizarSubmit();
        setBadge('loading', 'Buscando…');
        setAvisoMsg(false);
        limpiarIngreso();

        try {
            const url = smartcsetUrl('/routers/porteria/v1/salida/consultar.php') + '?' + new URLSearchParams({ documento, tipo_doc: selTipo.value });
            const res = await fetch(url, { headers: { Accept: 'application/json' } });
            const data = await res.json();

            if (!data.ok) {
                setBadge('error', data.error || 'Error al buscar');
                actualizarSubmit();
                return;
            }

            puedeSalir = Boolean(data.puede_salir);

            if (data.ingreso_abierto) {
                mostrarIngreso(data.ingreso_abierto);
            } else {
                mostrarSinIngresoActivo(data.persona);
            }
        } catch {
            puedeSalir = false;
            setBadge('error', 'Error de conexión');
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

    form.addEventListener('submit', (e) => {
        if (!inputPuerta?.value) {
            e.preventDefault();
            if (puertaError) puertaError.style.display = 'block';
            document.getElementById('puertas_grid')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            return;
        }
        if (!puedeSalir || !hidIngreso?.value) {
            e.preventDefault();
            setBadge('warn', 'Debe existir un ingreso activo');
            setAvisoMsg(true, 'Confirme el documento: solo se puede registrar salida con un ingreso abierto.');
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
});
