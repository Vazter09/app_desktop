/**
 * Menús: listado + modal crear/editar
 */
document.addEventListener('DOMContentLoaded', () => {
    const modalEl = document.getElementById('modalMenu');
    const form = document.getElementById('form_menu');
    const titulo = document.getElementById('menu-editor-titulo');
    const subtitulo = document.getElementById('menu-editor-subtitulo');
    const btnNuevo = document.getElementById('btn_nuevo_menu');
    const inputId = document.getElementById('f_id');
    const inputNom = document.getElementById('f_nom');
    const inputPadre = document.getElementById('f_padre');
    const inputPrograma = document.getElementById('f_programa');

    if (!modalEl || !form || typeof bootstrap === 'undefined') return;

    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);

    function resetUnsaved() {
        if (typeof window.resetUnsavedChanges === 'function') {
            window.resetUnsavedChanges();
        }
    }

    function limpiarFormulario() {
        inputId.readOnly = false;
        inputId.value = '';
        inputNom.value = '';
        inputPadre.value = '00';
        inputPrograma.value = '';
        document.querySelectorAll('#tabla-menus tr.menu-editando').forEach(tr => {
            tr.classList.remove('menu-editando');
        });
        resetUnsaved();
    }

    function abrirModal(modo, datos) {
        limpiarFormulario();

        if (modo === 'nuevo') {
            titulo.textContent = 'Nuevo menú';
            if (subtitulo) subtitulo.textContent = 'Defina ID, nombre y opcionalmente menú padre';
            modal.show();
            modalEl.addEventListener('shown.bs.modal', () => inputId.focus(), { once: true });
            return;
        }

        titulo.textContent = 'Editar menú';
        if (subtitulo) subtitulo.textContent = datos.id;
        inputId.value = datos.id;
        inputId.readOnly = true;
        inputNom.value = datos.nom;
        inputPadre.value = datos.padre;
        inputPrograma.value = datos.programa === 'no_aplica' ? '' : datos.programa;

        const fila = document.querySelector(`#tabla-menus tr[data-id="${CSS.escape(datos.id)}"]`);
        if (fila) fila.classList.add('menu-editando');

        modal.show();
        modalEl.addEventListener('shown.bs.modal', () => inputNom.focus(), { once: true });
    }

    document.querySelectorAll('.btn-editar-menu').forEach(btn => {
        btn.addEventListener('click', () => {
            abrirModal('editar', {
                id: btn.dataset.id,
                nom: btn.dataset.nom,
                padre: btn.dataset.padre,
                programa: btn.dataset.programa
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
            id_menu: inputId.value,
            nom_menu: inputNom.value,
            id_padre: inputPadre.value,
            nom_programa: inputPrograma.value || 'no_aplica',
        };
        try {
            const data = await SmartcsetMenusRouter.guardar(payload);
            modal.hide();
            if (typeof window.SmartcsetToast !== 'undefined') {
                window.SmartcsetToast.show('success', 'Listo', data.message);
            }
            setTimeout(() => window.location.reload(), 400);
        } catch (err) {
            alert(err.message);
        }
    });

    document.querySelectorAll('form.form-eliminar-menu').forEach((f) => {
        f.addEventListener('submit', async (e) => {
            e.preventDefault();
            const id = f.querySelector('input[name="hid_id_menu"]')?.value;
            if (!id) return;
            try {
                const data = await SmartcsetMenusRouter.eliminar(id);
                if (typeof window.SmartcsetToast !== 'undefined') {
                    window.SmartcsetToast.show('success', 'Listo', data.message);
                }
                setTimeout(() => window.location.reload(), 400);
            } catch (err) {
                alert(err.message);
            }
        });
    });
});
