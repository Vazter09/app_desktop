/**
 * Registro de ingresos — portería (captura PDF417, bloqueo ingreso activo).
 * Documentación línea por línea: docs/porteria-codigo-linea-a-linea.md
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
    const bloqueoMsg = document.getElementById('ingreso_bloqueado_msg');
    const btnSubmit = document.getElementById('btn_registrar_ingreso');
    const hidCaptura = document.getElementById('hid_captura_raw');
    const hidMetodo = document.getElementById('hid_metodo_aut');
    const form = document.getElementById('form_ingreso');

    if (!inputDoc || !form) return;

    let timer = null;
    let puedeIngresar = true;
    let consultaEnCurso = false;

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
        const hora = ingreso.fec_ingreso
            ? new Date(ingreso.fec_ingreso).toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' })
            : '—';
        setBadge('blocked', `Ingreso activo #${ingreso.id_ingreso}`);
        setBloqueoMsg(
            true,
            `Esta persona ya ingresó hoy (${hora}, puerta ${ingreso.id_entrada_centro}). `
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

        consultaEnCurso = true;
        actualizarSubmit();
        setBadge('loading', 'Buscando…');
        setBloqueoMsg(false);

        try {
            const res = await fetch(
                `consultar.php?${new URLSearchParams({ documento, tipo_doc: selTipo.value })}`,
                { headers: { Accept: 'application/json' } }
            );
            const data = await res.json();

            if (!data.ok) {
                puedeIngresar = true;
                setBadge('hide');
                actualizarSubmit();
                return;
            }

            puedeIngresar = Boolean(data.puede_ingresar);

            if (data.ingreso_abierto) {
                mostrarIngresoAbierto(data.ingreso_abierto);
            } else {
                setBloqueoMsg(false);
            }

            if (data.persona) {
                inputNom.value = data.persona.nom_persona || '';
                inputApe.value = data.persona.ape_persona || '';
                inputNom.readOnly = true;
                inputApe.readOnly = true;
                if (selTipoPersona && data.persona.id_tipo_persona) {
                    selTipoPersona.value = String(data.persona.id_tipo_persona);
                }
                const tipoNom = data.persona.nom_tipo_persona || 'registrada';
                if (puedeIngresar) {
                    setBadge('known', `Persona ${tipoNom}`);
                }
            } else {
                liberarNombres();
                if (puedeIngresar) {
                    setBadge('new', 'Persona nueva — indique el tipo');
                }
            }
        } catch {
            puedeIngresar = true;
            setBadge('hide');
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
            liberarNombres();
        }
        clearTimeout(timer);
        timer = setTimeout(() => consultarAcceso(false), 400);
    });

    selTipo?.addEventListener('change', () => {
        liberarNombres();
        consultarAcceso(true);
    });

    form.addEventListener('submit', (e) => {
        if (!inputPuerta?.value) {
            e.preventDefault();
            if (puertaError) puertaError.style.display = 'block';
            document.getElementById('puertas_grid')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            return;
        }
        if (!puedeIngresar) {
            e.preventDefault();
            setBadge('blocked', 'Ingreso bloqueado');
            return;
        }
        inputNom.readOnly = false;
        inputApe.readOnly = false;
    });

    if (PM) {
        PM.init({
            form,
            inputDoc,
            resetEscaner: form.dataset.ptReset === '1',
        });
    } else {
        inputDoc.focus();
    }
    actualizarSubmit();

    if (inputPuerta?.value) {
        const btn = document.querySelector(`.ing-puerta[data-puerta="${inputPuerta.value}"]`);
        if (btn) btn.classList.add('is-selected');
    }
});
