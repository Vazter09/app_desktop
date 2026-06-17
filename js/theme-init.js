/**
 * Aplica el tema claro guardado en localStorage antes del primer render.
 */
(function () {
    try {
        if (localStorage.getItem('smartcset_theme') === 'light') {
            document.body.classList.add('light-theme');
        }
    } catch (err) {
        /* noop: fallback a tema oscuro por defecto */
    }
})();
