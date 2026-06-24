/**
 * SmartCSET SPA — navegación parcial del sidebar.
 * Intercepta los enlaces del menú y reemplaza SOLO <main class="main-content">,
 * dejando fijos sidebar y topbar. Es OPT-IN y degrada con gracia:
 *   - Solo intercambia si la página destino contiene un elemento [data-spa].
 *   - Ante cualquier error (fetch, parseo, login expirado) hace navegación completa.
 * No toca el sidebar (lo gestiona layout.js), así que sus toggles persisten.
 */
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

    function setActiveMenu(url) {
        const path = abs(url).pathname;
        document.querySelectorAll('.sidebar .nav-item').forEach((el) => el.classList.remove('active'));
        let match = null;
        document.querySelectorAll('.sidebar a.nav-item[href]').forEach((a) => {
            if (abs(a.getAttribute('href')).pathname === path) {
                match = a;
            }
        });
        if (!match) {
            return;
        }
        match.classList.add('active');
        const section = match.closest('.nav-section');
        if (section) {
            section.classList.add('open');
            const parent = section.querySelector('.nav-item-parent');
            if (parent) {
                parent.classList.add('active');
            }
        }
    }

    function reinit(main) {
        if (window.SmartcsetListado && typeof window.SmartcsetListado.bind === 'function') {
            main.querySelectorAll('[data-smart-listado-host]').forEach((host) => window.SmartcsetListado.bind(host));
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
        if (!newMain || !newMain.querySelector('[data-spa]')) {
            return fullNav(url);
        }

        main.setAttribute('aria-busy', 'true');
        ensureStylesheets(doc);
        main.replaceChildren(...newMain.childNodes);
        if (doc.title) {
            document.title = doc.title;
        }
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
        const a = e.target.closest('.sidebar a.nav-item[data-spa-link][href]');
        if (!a) {
            return;
        }
        const href = a.getAttribute('href');
        if (!href || href.charAt(0) === '#' || a.target === '_blank' || !sameOrigin(href)) {
            return;
        }
        if (/\/logout\.php/i.test(href)) {
            return;
        }
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
})();
