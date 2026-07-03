/**
 * Cambio de tipo (20101, 20201, 20702, 20703) sin recargar sidebar: solo el bloque del listado.
 */
(function () {
    const host = document.getElementById('registro-listado-host');
    if (!host) return;

    const menuIds = ['20201', '20101', '20702', '20703'];

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

    async function loadListado(url, menuId, push) {
        const u = new URL(url, window.location.href);
        if (menuId) u.searchParams.set('menu', menuId);
        u.searchParams.set('partial', '1');

        host.classList.add('is-loading');
        try {
            const res = await fetch(u.toString(), {
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
            });
            if (!res.ok) throw new Error('No se pudo cargar el listado.');
            const html = await res.text();
            host.innerHTML = html;

            const root = host.querySelector('#registro-listado-root');
            const title = root?.dataset.pageTitle || 'Listado';
            setBreadcrumb(title);
            if (menuId) setActiveMenu(menuId);

            if (push) {
                const clean = new URL(url, window.location.href);
                if (menuId) clean.searchParams.set('menu', menuId);
                clean.searchParams.delete('partial');
                history.pushState({ menuId }, '', clean.pathname + clean.search);
            }
        } catch (e) {
            window.location.href = url;
        } finally {
            host.classList.remove('is-loading');
        }
    }

    document.addEventListener('click', (e) => {
        const link = e.target.closest('.sidebar a[href*="registro/listado.php"]');
        if (!link) return;

        e.preventDefault();
        const u = new URL(link.href, window.location.href);
        const menuId = u.searchParams.get('menu') || '';
        loadListado(link.href, menuId, true);
    });

    window.addEventListener('popstate', (e) => {
        const menuId = e.state?.menuId || new URL(window.location.href).searchParams.get('menu') || '20201';
        loadListado(window.location.pathname + window.location.search, menuId, false);
    });

    document.querySelectorAll('.sidebar a[href*="registro/listado.php"]').forEach((a) => {
        try {
            const u = new URL(a.href, window.location.href);
            const id = u.searchParams.get('menu');
            if (id) a.dataset.menuId = id;
        } catch (_) { /* ignore */ }
    });

    const initial = new URL(window.location.href).searchParams.get('menu') || '20201';
    setActiveMenu(initial);
})();
