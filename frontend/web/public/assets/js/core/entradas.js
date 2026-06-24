/**
 * Entradas al centro: listado + modal crear/editar (sede + código automático en alta)
 */
document.addEventListener('DOMContentLoaded', () => {
    const modalEl = document.getElementById('modalEntrada');
    const form = document.getElementById('form_entrada');
    const titulo = document.getElementById('entrada-editor-titulo');
    const subtitulo = document.getElementById('entrada-editor-subtitulo');
    const btnNuevo = document.getElementById('btn_nueva_entrada');
    const hidId = document.getElementById('hid_id_entrada');
    const inputNom = document.getElementById('f_nom');
    const selectSede = document.getElementById('f_sede');
    const codigoBadge = document.getElementById('f_codigo_badge');
    const codigoText = document.getElementById('f_codigo_text');
    const nomHint = document.getElementById('f_nom_hint');

    if (!modalEl || !form || !inputNom || typeof bootstrap === 'undefined') return;

    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);

    function resetUnsaved() {
        if (typeof window.resetUnsavedChanges === 'function') {
            window.resetUnsavedChanges();
        }
    }

    function valorSede(centro, sede) {
        return `${centro}:${sede}`;
    }

    function mostrarCodigo(id, visible) {
        if (!codigoBadge || !codigoText) return;
        if (visible && id) {
            codigoText.textContent = String(id);
            codigoBadge.classList.remove('d-none');
        } else {
            codigoBadge.classList.add('d-none');
            codigoText.textContent = '';
        }
    }

    function limpiarFormulario() {
        if (hidId) hidId.value = '';
        inputNom.value = '';
        if (selectSede) {
            selectSede.disabled = false;
            selectSede.value = '';
        }
        mostrarCodigo(null, false);
        if (nomHint) {
            nomHint.textContent = 'Al crear, el sistema asigna automáticamente el siguiente código libre (1–9).';
        }
        document.querySelectorAll('#tabla-entradas tr.entrada-editando').forEach(tr => {
            tr.classList.remove('entrada-editando');
        });
        resetUnsaved();
    }

    function abrirModal(modo, datos) {
        limpiarFormulario();

        if (modo === 'nuevo') {
            titulo.textContent = 'Nueva entrada';
            if (subtitulo) subtitulo.textContent = 'Elija la sede y el nombre; el código se asigna solo';
            modal.show();
            modalEl.addEventListener('shown.bs.modal', () => {
                if (selectSede) selectSede.focus();
            }, { once: true });
            return;
        }

        titulo.textContent = 'Editar entrada';
        if (subtitulo) subtitulo.textContent = 'Actualice sede o nombre de la puerta';
        if (hidId) hidId.value = String(datos.id);
        inputNom.value = datos.nom;
        mostrarCodigo(datos.id, true);
        if (nomHint) {
            nomHint.textContent = 'El código no se puede cambiar; solo nombre y sede.';
        }
        if (selectSede) {
            selectSede.value = valorSede(datos.centro, datos.sede);
        }

        const fila = document.querySelector(`#tabla-entradas tr[data-id="${datos.id}"]`);
        if (fila) fila.classList.add('entrada-editando');

        modal.show();
        modalEl.addEventListener('shown.bs.modal', () => inputNom.focus(), { once: true });
    }

    document.querySelectorAll('.btn-editar-entrada').forEach(btn => {
        btn.addEventListener('click', () => {
            abrirModal('editar', {
                id: parseInt(btn.dataset.id, 10),
                nom: btn.dataset.nom,
                centro: parseInt(btn.dataset.centro, 10),
                sede: parseInt(btn.dataset.sede, 10),
            });
        });
    });

    if (btnNuevo) {
        btnNuevo.addEventListener('click', () => abrirModal('nuevo'));
    }

    modalEl.addEventListener('hidden.bs.modal', limpiarFormulario);

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const payload = {
            id_entrada: hidId?.value || '',
            txt_nom_entrada: inputNom.value,
            sel_sede: selectSede?.value || '',
        };
        try {
            const data = await SmartcsetEntradasRouter.guardar(payload);
            modal.hide();
            if (typeof window.SmartcsetToast !== 'undefined') {
                window.SmartcsetToast.show('success', 'Listo', data.message || 'Guardado.');
            }
            setTimeout(() => window.location.reload(), 400);
        } catch (err) {
            if (typeof window.SmartcsetToast !== 'undefined') {
                window.SmartcsetToast.show('danger', 'Error', err.message);
            } else {
                alert(err.message);
            }
        }
    });

    document.querySelectorAll('form.form-eliminar-entrada').forEach((delForm) => {
        delForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const id = delForm.querySelector('input[name="hid_id_entrada"]')?.value;
            if (!id || !confirm('¿Eliminar esta entrada?')) return;
            try {
                await SmartcsetEntradasRouter.eliminar(id);
                window.location.reload();
            } catch (err) {
                alert(err.message);
            }
        });
    });
});
