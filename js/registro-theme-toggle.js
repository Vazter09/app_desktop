(function() {
    const toggle = document.getElementById('theme-toggle');
    const body = document.body;
    const storageKey = 'cset-theme-mode';

    if (!toggle || !body) {
        return;
    }

    const setTheme = theme => {
        body.classList.toggle('light-theme', theme === 'light');
        toggle.textContent = theme === 'light' ? '✹' : '☾';
        toggle.title = theme === 'light' ? 'Cambiar a modo oscuro' : 'Cambiar a modo claro';
        localStorage.setItem(storageKey, theme);
    };

    const savedTheme = localStorage.getItem(storageKey);
    const defaultTheme = savedTheme || (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
    setTheme(defaultTheme);

    toggle.addEventListener('click', () => {
        setTheme(body.classList.contains('light-theme') ? 'dark' : 'light');
    });
})();
