/**
 * Entradas al centro: listado + modal crear/editar
 */
document.addEventListener('DOMContentLoaded', () => {
    const modalEl = document.getElementById('modalEntrada');
    const form = document.getElementById('form_entrada');
    const titulo = document.getElementById('entrada-editor-titulo');
    const subtitulo = document.getElementById('entrada-editor-subtitulo');
    const btnNuevo = document.getElementById('btn_nueva_entrada');
    const inputId = document.getElementById('f_id');
    const inputNom = document.getElementById('f_nom');

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
        document.querySelectorAll('#tabla-entradas tr.entrada-editando').forEach(tr => {
            tr.classList.remove('entrada-editando');
        });
        resetUnsaved();
    }

    function abrirModal(modo, datos) {
        limpiarFormulario();

        if (modo === 'nuevo') {
            titulo.textContent = 'Nueva entrada';
            if (subtitulo) subtitulo.textContent = 'Asigne un código del 1 al 9 y un nombre';
            modal.show();
            modalEl.addEventListener('shown.bs.modal', () => inputId.focus(), { once: true });
            return;
        }

        titulo.textContent = 'Editar entrada';
        if (subtitulo) subtitulo.textContent = `Código ${datos.id}`;
        inputId.value = datos.id;
        inputId.readOnly = true;
        inputNom.value = datos.nom;

        const fila = document.querySelector(`#tabla-entradas tr[data-id="${datos.id}"]`);
        if (fila) fila.classList.add('entrada-editando');

        modal.show();
        modalEl.addEventListener('shown.bs.modal', () => inputNom.focus(), { once: true });
    }

    document.querySelectorAll('.btn-editar-entrada').forEach(btn => {
        btn.addEventListener('click', () => {
            abrirModal('editar', {
                id: parseInt(btn.dataset.id, 10),
                nom: btn.dataset.nom
            });
        });
    });

    if (btnNuevo) {
        btnNuevo.addEventListener('click', () => abrirModal('nuevo'));
    }

    modalEl.addEventListener('hidden.bs.modal', limpiarFormulario);
    form.addEventListener('submit', resetUnsaved);
});
