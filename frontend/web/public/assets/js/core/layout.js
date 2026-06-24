/* =====================================================
   LAYOUT JS - SmartCSET
   Toggle sidebar, persistencia, mobile overlay
   ===================================================== */

(function () {
    const sidebar = document.getElementById('sidebar');
    const contentWrapper = document.querySelector('.content-wrapper');
    const toggleBtn = document.getElementById('sidebar-toggle');
    const toggleMobileBtn = document.getElementById('sidebar-toggle-mobile');
    const overlay = document.getElementById('sidebar-overlay');
    const themeToggleBtn = document.getElementById('theme-toggle');
    const notificationsRoot = document.getElementById('topbar-notifications');
    const notificationsToggleBtn = document.getElementById('notifications-toggle');
    const notificationsPanel = document.getElementById('notifications-panel');
    const body = document.body;
    const themeStorageKey = 'smartcset_theme';
    const darkTheme = 'dark';
    const lightTheme = 'light';

    if (!sidebar) return;

    function getStoredTheme() {
        try {
            return localStorage.getItem(themeStorageKey);
        } catch (err) {
            return null;
        }
    }

    function setStoredTheme(value) {
        try {
            localStorage.setItem(themeStorageKey, value);
        } catch (err) {
            // noop: almacenamiento no disponible
        }
    }

    function updateThemeToggleIcon() {
        if (!themeToggleBtn) return;
        const icon = themeToggleBtn.querySelector('i');
        if (!icon) return;

        const isLight = body.classList.contains('light-theme');
        icon.className = isLight ? 'bi bi-sun-fill' : 'bi bi-moon-stars-fill';
        themeToggleBtn.title = isLight ? 'Cambiar a modo oscuro' : 'Cambiar a modo claro';
        themeToggleBtn.setAttribute('aria-label', isLight ? 'Cambiar a modo oscuro' : 'Cambiar a modo claro');
    }

    function applyTheme(theme) {
        body.classList.toggle('light-theme', theme === lightTheme);
        updateThemeToggleIcon();
    }

    const initialTheme = getStoredTheme() === lightTheme ? lightTheme : darkTheme;
    applyTheme(initialTheme);

    if (themeToggleBtn) {
        themeToggleBtn.addEventListener('click', function () {
            const nextTheme = body.classList.contains('light-theme') ? darkTheme : lightTheme;
            applyTheme(nextTheme);
            setStoredTheme(nextTheme);
        });
    }

    function setNotificationsOpen(open) {
        if (!notificationsToggleBtn || !notificationsPanel) return;
        notificationsToggleBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
        notificationsPanel.hidden = !open;
    }

    function closeNotificationsPanel() {
        setNotificationsOpen(false);
    }

    if (notificationsToggleBtn && notificationsPanel) {
        notificationsToggleBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            const isOpen = notificationsToggleBtn.getAttribute('aria-expanded') === 'true';
            setNotificationsOpen(!isOpen);
        });

        document.addEventListener('click', function (e) {
            if (!notificationsRoot || notificationsPanel.hidden) return;
            if (!notificationsRoot.contains(e.target)) {
                closeNotificationsPanel();
            }
        });

        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') closeNotificationsPanel();
        });
    }

    function updateToggleIcon() {
        if (!toggleBtn) return;
        const icon = toggleBtn.querySelector('i');
        if (!icon) return;
        if (sidebar.classList.contains('collapsed')) {
            icon.className = 'bi bi-layout-sidebar';
            toggleBtn.title = 'Expandir menú';
        } else {
            icon.className = 'bi bi-layout-sidebar-reverse';
            toggleBtn.title = 'Colapsar menú';
        }
    }

    // ── Restaurar estado desde localStorage ──
    const isCollapsed = localStorage.getItem('sidebar_collapsed') === 'true';
    if (isCollapsed) sidebar.classList.add('collapsed');
    updateToggleIcon();

    // ── Toggle desktop (colapsar/expandir) ──
    if (toggleBtn) {
        toggleBtn.addEventListener('click', function () {
            sidebar.classList.toggle('collapsed');
            localStorage.setItem('sidebar_collapsed', sidebar.classList.contains('collapsed'));
            updateToggleIcon();
        });
    }

    // ── Toggle mobile (abrir/cerrar como overlay) ──
    if (toggleMobileBtn) {
        toggleMobileBtn.addEventListener('click', function () {
            sidebar.classList.toggle('mobile-open');
            if (overlay) overlay.classList.toggle('active');
        });
    }

    // ── Cerrar sidebar en mobile al hacer clic en overlay ──
    if (overlay) {
        overlay.addEventListener('click', function () {
            sidebar.classList.remove('mobile-open');
            overlay.classList.remove('active');
        });
    }

    // ── Accordion: expandir/colapsar secciones del menú ──
    document.querySelectorAll('.nav-item-parent').forEach(function (item) {
        item.addEventListener('click', function (e) {
            e.preventDefault();
            const section = this.closest('.nav-section');
            if (!section) return;

            // Si la sidebar está colapsada, expandirla primero
            if (sidebar.classList.contains('collapsed') && window.innerWidth > 768) {
                sidebar.classList.remove('collapsed');
                localStorage.setItem('sidebar_collapsed', 'false');
            }

            section.classList.toggle('open');
        });
    });

    // ── Abrir automáticamente la sección del item activo ──
    const activeChild = document.querySelector('.nav-item.child.active');
    if (activeChild) {
        const parentSection = activeChild.closest('.nav-section');
        if (parentSection) parentSection.classList.add('open');
    }

    // ── Bloquear navegación hacia atrás ──
    history.pushState(null, null, location.href);
    window.onpopstate = function () { history.go(1); };

    // ── Aviso de cambios sin guardar (solo formularios marcados) ──
    let hasChanges = false;
    document.addEventListener('input', function (e) {
        const form = e.target.closest('form[data-watch-unsaved]');
        if (!form || e.target.type === 'hidden' || e.target.readOnly) return;
        const tag = e.target.tagName;
        if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') {
            hasChanges = true;
        }
    });
    window.addEventListener('beforeunload', function (e) {
        if (hasChanges) {
            e.preventDefault();
            e.returnValue = '';
        }
    });
    document.addEventListener('submit', function (e) {
        if (e.target.matches('form[data-watch-unsaved]')) {
            hasChanges = false;
        }
    });
    window.resetUnsavedChanges = function () {
        hasChanges = false;
    };
})();
