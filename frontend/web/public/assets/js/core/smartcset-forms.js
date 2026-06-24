/**
 * Comportamiento global de formularios SmartCSET
 * - Ocultar efecto de rueda en input[type="number"]
 * - Filtrar input[data-numeric-only] (p. ej. "1-9" en entradas)
 */
(function () {
    document.addEventListener('wheel', (e) => {
        const el = document.activeElement;
        if (el && el.matches && el.matches('input[type="number"]')) {
            el.blur();
        }
    }, { passive: true });

    document.addEventListener('input', (e) => {
        const input = e.target;
        if (!input.matches || !input.matches('input[data-numeric-only]')) return;
        if (input.matches('input[data-documento-captura]')) return;

        const mode = input.getAttribute('data-numeric-only');
        if (mode === '1-9') {
            input.value = input.value.replace(/[^1-9]/g, '').slice(0, 1);
            return;
        }

        const maxLen = input.maxLength > 0 ? input.maxLength : 32;
        input.value = input.value.replace(/\D/g, '').slice(0, maxLen);
    });
})();
