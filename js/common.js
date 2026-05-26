/**
 * JAVASCRIPT COMÚN - SistNomina V.1.4
 * Funcionalidad compartida por todos los archivos PHP
 */

// ===== BLOQUEADOR DE NAVEGACIÓN HACIA ATRÁS =====
history.pushState(null, null, location.href);
window.onpopstate = function () {
    history.go(1);
};

// ===== VALIDACIÓN DE CAMBIOS SIN GUARDAR =====
let hasChanges = false;

document.addEventListener('input', function(e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') {
        hasChanges = true;
    }
});

document.addEventListener('change', function(e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') {
        hasChanges = true;
    }
});

window.addEventListener('beforeunload', function (e) {
    if (hasChanges) {
        e.preventDefault();
        e.returnValue = '';
    }
});

document.addEventListener('submit', function() {
    hasChanges = false;
});

// ===== FUNCIONES AUXILIARES PARA CRUD =====

/**
 * Función genérica QBE (Query By Example) para edición
 * Rellena los campos del formulario con datos de una fila
 * @param {Object} fieldMap - Mapeo de id_elemento → valor
 */
function fillFormFields(fieldMap) {
    for (const [fieldId, value] of Object.entries(fieldMap)) {
        const element = document.getElementById(fieldId);
        if (element) {
            if (element.tagName === 'SELECT' || element.type === 'select-one') {
                element.value = value;
            } else if (element.type === 'checkbox') {
                element.checked = Boolean(value);
            } else if (element.type === 'radio') {
                const radio = document.querySelector(`input[name="${element.name}"][value="${value}"]`);
                if (radio) radio.checked = true;
            } else {
                element.value = value;
            }
        }
    }
}

/**
 * Función para hacer un campo solo lectura
 * @param {string} fieldId - ID del elemento
 */
function lockField(fieldId) {
    const element = document.getElementById(fieldId);
    if (element) {
        if (element.tagName === 'SELECT') {
            element.setAttribute('readonly', 'true');
            element.style.pointerEvents = 'none';
            element.style.backgroundColor = '#e9ecef';
        } else {
            element.readOnly = true;
        }
    }
}

/**
 * Función para desbloquear un campo
 * @param {string} fieldId - ID del elemento
 */
function unlockField(fieldId) {
    const element = document.getElementById(fieldId);
    if (element) {
        if (element.tagName === 'SELECT') {
            element.removeAttribute('readonly');
            element.style.pointerEvents = 'auto';
            element.style.backgroundColor = '';
        } else {
            element.readOnly = false;
        }
    }
}

/**
 * Scroll suave hacia un elemento
 * @param {HTMLElement | string} element - Elemento o ID
 */
function smoothScroll(element) {
    if (typeof element === 'string') {
        element = document.getElementById(element);
    }
    if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

/**
 * Limpia todos los campos de un formulario
 * @param {string} formId - ID del formulario
 */
function clearForm(formId) {
    const form = document.getElementById(formId) || document.querySelector('form');
    if (form) {
        const inputs = form.querySelectorAll('input, textarea, select');
        inputs.forEach(input => {
            if (input.type === 'checkbox' || input.type === 'radio') {
                input.checked = false;
            } else {
                input.value = '';
            }
            unlockField(input.id);
        });
        hasChanges = false;
    }
}
