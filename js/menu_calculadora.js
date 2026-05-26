/**
 * CALCULADORA FLOTANTE - SistNomina V.1.4
 * Widget interactivo de cálculo con drag & drop
 */

// ===== ELEMENTOS DEL DOM =====
const btnOpenCalc = document.getElementById('btn_open_calc');
const calcWidget = document.getElementById('calc-widget');
const calcClose = document.getElementById('calc-close');
const calcHeader = document.getElementById('calc-header');
const calcDisplay = document.getElementById('calc-display');

// ===== VARIABLES DE ESTADO =====
let calcExpression = '';

// Variables para Drag de la calculadora
let isDraggingCalc = false;
let calcDragOffsetX = 0;
let calcDragOffsetY = 0;

// Variables para Drag del botón lanzador
let isDraggingLauncher = false;
let launcherDragOffsetX = 0;
let launcherDragOffsetY = 0;

// ===== FUNCIONES AUXILIARES =====

/**
 * Actualiza el display de la calculadora
 * @param {string|number} valor
 */
function actualizarDisplay(valor) {
    calcDisplay.value = String(valor);
}

/**
 * Evalúa una expresión matemática de forma segura
 * @param {string} expr - Expresión a evaluar
 * @returns {number|string} Resultado o 'ERROR'
 */
function evaluarExpresion(expr) {
    try {
        const sanitized = expr
            .replace(/×/g, '*')
            .replace(/÷/g, '/')
            .replace(/−/g, '-')
            .replace(/[^0-9.+\-*/()%]/g, '');
        // Evaluación segura: usa Function para evitar eval directo
        const result = Function('return ' + sanitized)();
        return Number.isFinite(result) ? result : 'ERROR';
    } catch {
        return 'ERROR';
    }
}

/**
 * Reinicia la calculadora
 */
function resetCalc() {
    calcExpression = '';
    actualizarDisplay('0');
}

/**
 * Procesa la tecla presionada en la calculadora
 * @param {string} key - Tecla presionada
 */
function onCalcKey(key) {
    if (key === 'C') {
        resetCalc();
        return;
    }

    if (key === '⌫') {
        calcExpression = calcExpression.slice(0, -1);
        actualizarDisplay(calcExpression || '0');
        return;
    }

    if (key === '=') {
        const result = evaluarExpresion(calcExpression);
        calcExpression = String(result);
        actualizarDisplay(calcExpression);
        return;
    }

    if (key === '%') {
        const value = parseFloat(calcExpression);
        if (!Number.isNaN(value)) {
            calcExpression = String(value / 100);
            actualizarDisplay(calcExpression);
        }
        return;
    }

    const operadores = ['+', '-', '*', '/', '×', '÷'];
    const lastChar = calcExpression.slice(-1);
    if (operadores.includes(key) && operadores.includes(lastChar)) {
        calcExpression = calcExpression.slice(0, -1) + key;
    } else {
        calcExpression += key;
    }

    actualizarDisplay(calcExpression);
}

/**
 * Alterna visibilidad de la calculadora
 */
function toggleCalc() {
    const hidden = calcWidget.classList.toggle('calc-hidden');
    if (!hidden) {
        resetCalc();
    }
}

// ===== EVENT LISTENERS =====

// Botón de abrir/cerrar calculadora
if (btnOpenCalc) {
    btnOpenCalc.addEventListener('click', function (e) {
        e.preventDefault();
        toggleCalc();
    });
}

// Botón de cerrar (X)
if (calcClose) {
    calcClose.addEventListener('click', function () {
        calcWidget.classList.add('calc-hidden');
    });
}

// ===== DRAG & DROP DE LA CALCULADORA =====

if (calcHeader) {
    calcHeader.addEventListener('mousedown', function (e) {
        isDraggingCalc = true;
        const rect = calcWidget.getBoundingClientRect();
        calcDragOffsetX = e.clientX - rect.left;
        calcDragOffsetY = e.clientY - rect.top;
        document.body.style.userSelect = 'none';
    });
}

// ===== DRAG & DROP DEL BOTÓN LANZADOR =====

if (btnOpenCalc) {
    btnOpenCalc.addEventListener('mousedown', function (e) {
        isDraggingLauncher = true;
        const rect = btnOpenCalc.getBoundingClientRect();
        launcherDragOffsetX = e.clientX - rect.left;
        launcherDragOffsetY = e.clientY - rect.top;
        document.body.style.userSelect = 'none';
    });
}

// Movimiento del ratón
document.addEventListener('mousemove', function (e) {
    if (isDraggingCalc) {
        calcWidget.style.left = `${e.clientX - calcDragOffsetX}px`;
        calcWidget.style.top = `${e.clientY - calcDragOffsetY}px`;
        calcWidget.style.right = 'auto';
        calcWidget.style.bottom = 'auto';
    }
    if (isDraggingLauncher) {
        btnOpenCalc.style.left = `${e.clientX - launcherDragOffsetX}px`;
        btnOpenCalc.style.top = `${e.clientY - launcherDragOffsetY}px`;
        btnOpenCalc.style.right = 'auto';
        btnOpenCalc.style.bottom = 'auto';
    }
});

// Fin del arrastre
document.addEventListener('mouseup', function () {
    if (isDraggingCalc || isDraggingLauncher) {
        document.body.style.userSelect = '';
    }
    isDraggingCalc = false;
    isDraggingLauncher = false;
});

// ===== BOTONES DE LA CALCULADORA =====

document.querySelectorAll('#calc-widget .calc-button').forEach(btn => {
    btn.addEventListener('click', function () {
        onCalcKey(this.getAttribute('data-key'));
    });
});
