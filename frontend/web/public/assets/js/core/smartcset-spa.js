/**
 * SmartCSET SPA — navegación parcial sin recargar sidebar/topbar.
 * Intercambia solo <main class="main-content">; degrada a navegación completa si falla.
 */
window.smartcsetOnPageReady = function (fn) {
    if (typeof fn !== 'function') {
        return;
    }
    if (document.readyState !== 'loading') {
        fn();
    } else {
        document.addEventListener('DOMContentLoaded', fn, { once: true });
    }
    document.addEventListener('smartcset:content-loaded', fn);
};

(function () {
    'use strict';

    const MAIN = 'main.main-content';

    if (!window.history || !window.fetch || !document.querySelector(MAIN)) {
        return;
    }

    function abs(url) {
        return new URL(url, window.location.href);
    }

    function sameOrigin(url) {
        try {
            return abs(url).origin === window.location.origin;
        } catch (e) {
            return false;
        }
    }

    function fullNav(url) {
        window.location.href = url;
    }

    function isInternalPagesPath(pathname) {
        return /\/pages\//.test(pathname);
    }

    function isSpaLink(anchor) {
        if (!anchor || anchor.tagName !== 'A') {
            return false;
        }
        const href = anchor.getAttribute('href');
        if (!href || href.charAt(0) === '#' || anchor.target === '_blank' || anchor.hasAttribute('download')) {
            return false;
        }
        if (!sameOrigin(href)) {
            return false;
        }
        if (/\/logout\.php/i.test(href)) {
            return false;
        }
        if (anchor.closest('form')) {
            return false;
        }

        const path = abs(href).pathname;
        if (!isInternalPagesPath(path)) {
            return anchor.hasAttribute('data-spa-link');
        }

        if (anchor.closest('.sidebar')) {
            return anchor.matches('a.nav-item[href]');
        }
        if (anchor.closest(MAIN)) {
            return true;
        }

        return anchor.hasAttribute('data-spa-link');
    }

    function loadedSrcs() {
        return new Set(
            Array.from(document.scripts)
                .map((s) => s.src)
                .filter(Boolean)
        );
    }

    function ensureStylesheets(doc) {
        const have = new Set(
            Array.from(document.querySelectorAll('link[rel="stylesheet"][href]'))
                .map((l) => abs(l.getAttribute('href')).href)
        );
        doc.querySelectorAll('link[rel="stylesheet"][href]').forEach((l) => {
            const href = abs(l.getAttribute('href')).href;
            if (!have.has(href)) {
                const link = document.createElement('link');
                link.rel = 'stylesheet';
                link.href = l.getAttribute('href');
                document.head.appendChild(link);
            }
        });
    }

    function ensureScripts(doc) {
        const have = loadedSrcs();
        const pending = Array.from(doc.querySelectorAll('body script[src]'))
            .map((s) => abs(s.getAttribute('src')).href)
            .filter((src) => !have.has(src));
        return Promise.all(
            pending.map(
                (src) =>
                    new Promise((resolve) => {
                        const s = document.createElement('script');
                        s.src = src;
                        s.onload = resolve;
                        s.onerror = resolve;
                        document.body.appendChild(s);
                    })
            )
        );
    }

    function runInlineScripts(container) {
        container.querySelectorAll('script:not([src])').forEach((old) => {
            const s = document.createElement('script');
            for (const attr of old.attributes) {
                s.setAttribute(attr.name, attr.value);
            }
            s.textContent = old.textContent;
            old.replaceWith(s);
        });
    }

    function clearSidebarMenuState() {
        document.querySelectorAll('.sidebar .nav-section, .sidebar .nav-subsection').forEach((el) => {
            el.classList.remove('open');
        });
        document.querySelectorAll('.sidebar .nav-item').forEach((el) => {
            el.classList.remove('active', 'has-active-child');
        });
    }

    function openSidebarAncestors(activeEl) {
        let node = activeEl.parentElement;
        while (node) {
            if (node.classList.contains('nav-children')) {
                const section = node.parentElement;
                if (
                    section
                    && (section.classList.contains('nav-section') || section.classList.contains('nav-subsection'))
                ) {
                    section.classList.add('open');
                    const trigger = section.querySelector(':scope > .nav-item-parent, :scope > .nav-item-group');
                    if (trigger && trigger !== activeEl && !trigger.classList.contains('active')) {
                        trigger.classList.add('has-active-child');
                    }
                }
            }
            node = node.parentElement;
        }
    }

    function findSidebarLinkByMenuId(menuId) {
        if (menuId === '0') {
            return (
                document.querySelector('.sidebar a.nav-item[data-menu-id="0"]')
                || document.querySelector('.sidebar a.nav-item[href*="menu_principal"]')
            );
        }
        if (!menuId) {
            return null;
        }
        return document.querySelector(
            '.sidebar a.nav-item[data-menu-id="' + CSS.escape(menuId) + '"]'
        );
    }

    function applySidebarActive(activeEl) {
        if (!activeEl) {
            return false;
        }
        activeEl.classList.add('active');
        openSidebarAncestors(activeEl);
        return true;
    }

    function setActiveMenuById(menuId) {
        return applySidebarActive(findSidebarLinkByMenuId(menuId));
    }

    function setActiveMenuByUrl(url) {
        const target = abs(url);
        const targetPath = target.pathname;
        const targetSearch = target.search || '';

        let match = null;
        let exactMatch = null;

        document.querySelectorAll('.sidebar a.nav-item[href]').forEach((a) => {
            const link = abs(a.getAttribute('href'));
            if (link.pathname !== targetPath) {
                return;
            }
            if (link.search === targetSearch) {
                exactMatch = a;
            }
            if (!match) {
                match = a;
            }
        });

        return applySidebarActive(exactMatch || match);
    }

    function setActiveMenu(url) {
        clearSidebarMenuState();

        const cfg = document.getElementById('smartcset-sesion-presencia');
        if (cfg && cfg.hasAttribute('data-active-menu-id')) {
            if (setActiveMenuById(cfg.getAttribute('data-active-menu-id') || '')) {
                return;
            }
        }

        setActiveMenuByUrl(url);
    }

    function updateTopbar(doc) {
        const newCurrent = doc.querySelector('.topbar-breadcrumb .current');
        const current = document.querySelector('.topbar-breadcrumb .current');
        if (newCurrent && current) {
            current.textContent = newCurrent.textContent;
        } else if (newCurrent && !current) {
            const nav = document.querySelector('.topbar-breadcrumb');
            if (nav) {
                const sep = document.createElement('span');
                sep.className = 'separator';
                sep.innerHTML = '<i class="bi bi-chevron-right"></i>';
                const span = document.createElement('span');
                span.className = 'current';
                span.textContent = newCurrent.textContent;
                nav.appendChild(sep);
                nav.appendChild(span);
            }
        } else if (!newCurrent && current) {
            const sep = current.previousElementSibling;
            current.remove();
            if (sep && sep.classList.contains('separator')) {
                sep.remove();
            }
        }
    }

    function syncPresenciaMenu(doc) {
        const cfg = document.getElementById('smartcset-sesion-presencia');
        const incoming = doc.getElementById('smartcset-sesion-presencia');
        if (!cfg || !incoming) {
            return;
        }
        if (incoming.hasAttribute('data-active-menu-id')) {
            cfg.setAttribute('data-active-menu-id', incoming.getAttribute('data-active-menu-id') || '');
        } else {
            cfg.removeAttribute('data-active-menu-id');
        }
    }

    function reinit(main) {
        if (window.SmartcsetListado && typeof window.SmartcsetListado.bind === 'function') {
            main.querySelectorAll('[data-smart-listado-host]').forEach((host) => window.SmartcsetListado.bind(host));
        }
        if (window.SmartToast && typeof window.SmartToast.showFlashFromPage === 'function') {
            window.SmartToast.showFlashFromPage();
        }
        document.dispatchEvent(new CustomEvent('smartcset:content-loaded', { detail: { main } }));
    }

    async function navigate(url, push) {
        const main = document.querySelector(MAIN);
        if (!main) {
            return fullNav(url);
        }

        let html;
        try {
            const res = await fetch(url, {
                headers: { 'X-Smartcset-Spa': '1' },
                credentials: 'same-origin',
            });
            const ctype = res.headers.get('content-type') || '';
            if (!res.ok || res.redirected || !ctype.includes('text/html')) {
                return fullNav(url);
            }
            html = await res.text();
        } catch (e) {
            return fullNav(url);
        }

        const doc = new DOMParser().parseFromString(html, 'text/html');
        const newMain = doc.querySelector(MAIN);
        if (!newMain || !newMain.hasAttribute('data-spa')) {
            return fullNav(url);
        }

        main.setAttribute('aria-busy', 'true');
        ensureStylesheets(doc);
        main.replaceChildren(...newMain.childNodes);
        if (doc.title) {
            document.title = doc.title;
        }
        updateTopbar(doc);
        syncPresenciaMenu(doc);
        if (push) {
            window.history.pushState({ spa: true }, '', url);
        }
        setActiveMenu(url);

        await ensureScripts(doc);
        runInlineScripts(main);
        reinit(main);

        main.removeAttribute('aria-busy');
        window.scrollTo(0, 0);
    }

    document.addEventListener('click', function (e) {
        if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) {
            return;
        }
        const a = e.target.closest('a[href]');
        if (!isSpaLink(a)) {
            return;
        }
        const href = a.getAttribute('href');
        if (abs(href).href === window.location.href) {
            e.preventDefault();
            return;
        }
        e.preventDefault();
        navigate(href, true);
    });

    window.addEventListener('popstate', function () {
        navigate(window.location.href, false);
    });

    if (!window.history.state || !window.history.state.spa) {
        window.history.replaceState({ spa: true }, '', window.location.href);
    }

    setActiveMenu(window.location.href);
})();
