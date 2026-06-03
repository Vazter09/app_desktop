/**
 * Navegación entre listados Personas (0301–0304) sin recargar el sidebar.
 */
(function () {
    const host = document.getElementById('personas-listado-host');
    if (!host) return;

    const menuIds = ['0301', '0302', '0303', '0304'];
    const linkSelector = '.sidebar a[href*="/admin/personas/"]';

    function setActiveMenu(menuId) {
        document.querySelectorAll('.sidebar .nav-item.child').forEach((el) => {
            el.classList.toggle('active', el.dataset.menuId === menuId);
        });
    }

    function setBreadcrumb(title) {
        const current = document.querySelector('.topbar-breadcrumb .current');
        if (current) current.textContent = title;
        document.title = title + ' | SmartCSET';
    }

    function menuIdFromUrl(url) {
        const link = document.querySelector(`${linkSelector}[href="${url}"], ${linkSelector}[href="${url}/"]`);
        if (link?.dataset?.menuId) return link.dataset.menuId;
        try {
            const u = new URL(url, window.location.href);
            const match = u.pathname.match(/\/admin\/personas\/([^/]+)\//);
            if (!match) return '';
            const bySlug = {
                aprendices: '0301',
                instructores: '0302',
                funcionarios: '0303',
                contratistas: '0304',
            };
            return bySlug[match[1]] || '';
        } catch (_) {
            return '';
        }
    }

    function syncBreadcrumbFromHost() {
        const root = host.querySelector('#personas-listado-root');
        const title = root?.dataset.pageTitle || 'Listado';
        setBreadcrumb(title);
    }

    async function loadListado(url, menuId, push) {
        if (!window.SmartcsetListado?.loadIntoHost) {
            window.location.href = url;
            return;
        }

        host.dataset.smartListadoBound = '';
        await window.SmartcsetListado.loadIntoHost(host, url, push);

        const resolvedMenu = menuId || menuIdFromUrl(url) || host.dataset.activeMenu || '';
        if (resolvedMenu) {
            host.dataset.activeMenu = resolvedMenu;
            setActiveMenu(resolvedMenu);
        }
        syncBreadcrumbFromHost();

        if (push && window.history?.state) {
            history.replaceState({ menuId: resolvedMenu, smartListado: true }, '', window.location.href);
        }
    }

    document.addEventListener('click', (e) => {
        const link = e.target.closest(linkSelector);
        if (!link) return;
        if (!link.href.includes('/index.php')) return;

        e.preventDefault();
        const menuId = link.dataset.menuId || menuIdFromUrl(link.href) || '';
        loadListado(link.href, menuId, true);
    });

    window.addEventListener('popstate', () => {
        const menuId = host.dataset.activeMenu || menuIds[0];
        loadListado(window.location.href, menuId, false);
    });

    host.addEventListener('smartcset:listado:mounted', () => {
        host.dataset.smartListadoBound = '';
        if (window.SmartcsetListado?.bind) {
            window.SmartcsetListado.bind(host);
        }
        syncBreadcrumbFromHost();
    });

    document.querySelectorAll(linkSelector).forEach((a) => {
        if (!a.href.includes('/index.php')) return;
        try {
            const id = a.dataset.menuId || menuIdFromUrl(a.href);
            if (id) a.dataset.menuId = id;
        } catch (_) { /* ignore */ }
    });

    const initial = host.dataset.activeMenu || menuIds[0];
    setActiveMenu(initial);
    syncBreadcrumbFromHost();
})();
