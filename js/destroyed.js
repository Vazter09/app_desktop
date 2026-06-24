/**
 * Smart CSET - Control de Salida Global con Historial y Modal Cyberpunk
 * Funcionalidad: Intercepta la flecha atrás, muestra modal interactivo y destruye datos del formulario.
 */

(function () {
    if (window.SmartCSET_ExitGuard) return;
    window.SmartCSET_ExitGuard = true;

    // --- PASO 1: MANIPULACIÓN DEL HISTORIAL (LA TRAMPA) ---
    history.pushState({ page: 'form_editing' }, document.title, window.location.href);

    window.addEventListener('popstate', function (event) {
        openExitModal();
        history.pushState({ page: 'form_editing' }, document.title, window.location.href);
    });

    window.destroyed = function() {
        // Busca cualquier etiqueta <form> en la página actual de manera abstracta
        const activeForm = document.querySelector('form');
        if (activeForm) {
            // 1. Resetea los campos a sus valores iniciales/vacíos por defecto
            activeForm.reset();

            // 2. Limpieza forzada manual por seguridad (remueve textos ingresados o seleccionados)
            const inputs = activeForm.querySelectorAll('input, select, textarea');
            inputs.forEach(input => {
                if (input.type === 'checkbox' || input.type === 'radio') {
                    input.checked = false;
                } else if (input.tagName.toLowerCase() === 'select') {
                    input.selectedIndex = 0;
                } else {
                    input.value = '';
                }
            });
        }
        
        // Limpiamos también el almacenamiento de sesión si se llegó a usar para persistir datos temporales
        sessionStorage.clear();
    };

    const modalHTML = `
        <div class="cset-modal-overlay" id="csetExitModal">
            <div class="cset-modal-box">
                <h2 class="cset-modal-title">⚠ Confirmación de Salida</h2>
                <p class="cset-modal-text">¿Está seguro de que desea salir del formulario? Los cambios no guardados se perderán permanentemente.</p>
                <div class="cset-modal-actions">
                    <button type="button" class="cset-btn" id="csetBtnCancelar">Permanecer</button>
                    <button type="button" class="cset-btn cset-btn-danger" id="csetBtnSalir">Salir del Formulario</button>
                </div>
            </div>
        </div>
    `;

    document.body.insertAdjacentHTML('beforeend', modalHTML);

    const modalOverlay = document.getElementById('csetExitModal');
    const btnCancelar = document.getElementById('csetBtnCancelar');
    const btnSalir = document.getElementById('csetBtnSalir');

    function openExitModal() {
        modalOverlay.classList.add('is-open');
    }

    function closeExitModal() {
        modalOverlay.classList.remove('is-open');
    }

    btnCancelar.addEventListener('click', closeExitModal);

    btnSalir.addEventListener('click', function () {
        // Ejecutamos la destrucción radical de los campos
        window.destroyed();
        
        // Rompemos el bucle del historial y retrocedemos de forma real
        window.removeEventListener('popstate', arguments.callee);
        history.go(-2); 
    });

})();