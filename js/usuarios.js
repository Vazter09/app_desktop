/**
 * UI Usuarios: listado + modal Bootstrap para crear/editar
 */
document.addEventListener('DOMContentLoaded', () => {
    const modalEl = document.getElementById('modalUsuario');
    const form = document.getElementById('form_usuario');
    const tituloEditor = document.getElementById('editor-titulo');
    const subtituloEditor = document.getElementById('editor-subtitulo');
    const passAyuda = document.getElementById('f_pass_ayuda');
    const btnNuevo = document.getElementById('btn_nuevo_usuario');
    const passInput = document.getElementById('f_pass');

    if (!modalEl || !form || typeof bootstrap === 'undefined') return;

    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);

    function resetUnsaved() {
        if (typeof window.resetUnsavedChanges === 'function') {
            window.resetUnsavedChanges();
        }
    }

    function limpiarEditor() {
        document.getElementById('f_id').readOnly = false;
        document.getElementById('f_id').value = '';
        document.getElementById('f_nom').value = '';
        document.getElementById('f_mail').value = '';
        if (passInput) {
            passInput.value = '';
            passInput.required = true;
            passInput.placeholder = 'Mínimo 12 caracteres';
            passInput.minLength = 12;
        }
        if (passAyuda) {
            passAyuda.textContent = 'Obligatoria al crear (mín. 12). Al editar, déjela vacía para no cambiarla.';
        }
        document.getElementById('f_adm').checked = false;
        document.getElementById('f_est').checked = true;
        document.querySelectorAll('#tabla-usuarios tr.usuario-editando').forEach(tr => {
            tr.classList.remove('usuario-editando');
        });
        resetUnsaved();
    }

    function abrirModal(modo, usuario) {
        limpiarEditor();

        if (modo === 'nuevo') {
            tituloEditor.textContent = 'Nuevo usuario';
            if (subtituloEditor) subtituloEditor.textContent = 'Registre un usuario en el sistema';
            if (passInput) passInput.required = true;
            if (passAyuda) passAyuda.textContent = 'Obligatoria al crear (mínimo 12 caracteres).';
            modal.show();
            modalEl.addEventListener('shown.bs.modal', () => document.getElementById('f_id').focus(), { once: true });
            return;
        }

        tituloEditor.textContent = 'Editar usuario';
        if (subtituloEditor) subtituloEditor.textContent = 'Modifique los datos y guarde los cambios';
        if (passAyuda) passAyuda.textContent = 'Deje vacía la contraseña para mantener la actual.';
        document.getElementById('f_id').value = usuario.id;
        document.getElementById('f_id').readOnly = true;
        document.getElementById('f_nom').value = usuario.nom;
        document.getElementById('f_mail').value = usuario.mail;
        document.getElementById('f_adm').checked = usuario.adm;
        document.getElementById('f_est').checked = usuario.est;
        if (passInput) {
            passInput.required = false;
            passInput.placeholder = 'Sin cambios si se deja vacío';
        }

        const fila = document.querySelector(`#tabla-usuarios tr[data-id="${CSS.escape(usuario.id)}"]`);
        if (fila) fila.classList.add('usuario-editando');

        modal.show();
        modalEl.addEventListener('shown.bs.modal', () => document.getElementById('f_nom').focus(), { once: true });
    }

    document.querySelectorAll('.btn-editar-usuario').forEach(btn => {
        btn.addEventListener('click', () => {
            abrirModal('editar', {
                id: btn.dataset.id,
                nom: btn.dataset.nom,
                mail: btn.dataset.mail,
                adm: btn.dataset.adm === '1',
                est: btn.dataset.est === '1'
            });
        });
    });

    if (btnNuevo) {
        btnNuevo.addEventListener('click', () => abrirModal('nuevo'));
    }

    modalEl.addEventListener('hidden.bs.modal', limpiarEditor);
    form.addEventListener('submit', resetUnsaved);
});
