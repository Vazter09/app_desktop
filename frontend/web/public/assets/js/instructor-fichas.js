(function () {
    'use strict';

    const page = document.getElementById('inst-fichas-page');
    if (!page) {
        return;
    }

    const detalle = document.getElementById('inst-fichas-detalle');
    const basePath = page.dataset.basePath || window.location.pathname;
    const form = document.getElementById('inst-filtros-form');

    function buildUrl(params) {
        const qs = new URLSearchParams(params);
        return basePath + '?' + qs.toString();
    }

    async function refreshDetalle(params) {
        if (!detalle) {
            return;
        }
        const url = buildUrl(Object.assign({}, params, { partial: '1' }));
        try {
            const res = await fetch(url, {
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                credentials: 'same-origin',
            });
            if (!res.ok) {
                return;
            }
            detalle.innerHTML = await res.text();
            bindForm();
        } catch (_e) {
            /* fallback: navegación completa */
        }
    }

    function bindForm() {
        const f = document.getElementById('inst-filtros-form');
        if (!f) {
            return;
        }
        f.addEventListener('submit', function (ev) {
            ev.preventDefault();
            const fd = new FormData(f);
            const params = {};
            fd.forEach(function (value, key) {
                if (String(value).trim() !== '') {
                    params[key] = String(value);
                }
            });
            const url = buildUrl(params);
            window.history.pushState({}, '', url);
            refreshDetalle(params);
        });
    }

    bindForm();

    page.querySelectorAll('.inst-ficha-item').forEach(function (link) {
        link.addEventListener('click', function (ev) {
            if (ev.metaKey || ev.ctrlKey || ev.shiftKey || ev.altKey) {
                return;
            }
            ev.preventDefault();
            const url = new URL(link.href, window.location.origin);
            const params = {};
            url.searchParams.forEach(function (value, key) {
                params[key] = value;
            });
            page.querySelectorAll('.inst-ficha-item').forEach(function (el) {
                el.classList.remove('active');
            });
            link.classList.add('active');
            window.history.pushState({}, '', url.pathname + url.search);
            refreshDetalle(params);
        });
    });
})();
