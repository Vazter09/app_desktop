(function () {
    const toggle = document.getElementById('theme-toggle');
    const body = document.body;
    const storageKey = 'smartcset_theme';
    const legacyKey = 'cset-theme-mode';
    const lightTheme = 'light';
    const darkTheme = 'dark';

    if (!toggle || !body) {
        return;
    }

    function getStoredTheme() {
        try {
            const current = localStorage.getItem(storageKey);
            if (current === lightTheme || current === darkTheme) {
                return current;
            }
            const legacy = localStorage.getItem(legacyKey);
            if (legacy === lightTheme || legacy === darkTheme) {
                localStorage.setItem(storageKey, legacy);
                localStorage.removeItem(legacyKey);
                return legacy;
            }
        } catch (err) {
            /* noop: almacenamiento no disponible */
        }
        return null;
    }

    function setStoredTheme(value) {
        try {
            localStorage.setItem(storageKey, value);
        } catch (err) {
            /* noop */
        }
    }

    function applyTheme(theme) {
        const isLight = theme === lightTheme;
        body.classList.toggle('light-theme', isLight);
        toggle.textContent = isLight ? '✹' : '☾';
        toggle.title = isLight ? 'Cambiar a modo oscuro' : 'Cambiar a modo claro';
        toggle.setAttribute('aria-label', toggle.title);
    }

    applyTheme(getStoredTheme() === lightTheme ? lightTheme : darkTheme);

    toggle.addEventListener('click', function () {
        const nextTheme = body.classList.contains('light-theme') ? darkTheme : lightTheme;
        applyTheme(nextTheme);
        setStoredTheme(nextTheme);
    });
})();
