/**
 * Comportamiento reutilizable de listados: filtros GET y paginación vía AJAX partial.
 * El contenedor debe tener id personas-listado-host (o data-smart-listado-host).
 */
(function () {
    const PARTIAL_PARAM = 'partial';
    const PARTIAL_VALUE = '1';

    function getHost(el) {
        return el?.closest?.('[data-smart-listado-host]')
            || document.getElementById('personas-listado-host');
    }

    async function fetchPartial(url) {
        const u = new URL(url, window.location.href);
        u.searchParams.set(PARTIAL_PARAM, PARTIAL_VALUE);

        const res = await fetch(u.toString(), {
            headers: { 'X-Requested-With': 'XMLHttpRequest' },
        });
        if (!res.ok) {
            throw new Error('No se pudo cargar el listado.');
        }
        return res.text();
    }

    function updateHistory(url, push) {
        const clean = new URL(url, window.location.href);
        clean.searchParams.delete(PARTIAL_PARAM);
        if (push) {
            history.pushState({ smartListado: true }, '', clean.pathname + clean.search);
        }
    }

    function dispatchMounted(host) {
        host.dispatchEvent(new CustomEvent('smartcset:listado:mounted', { bubbles: true }));
    }

    async function loadIntoHost(host, url, push) {
        host.classList.add('is-loading');
        try {
            const html = await fetchPartial(url);
            host.innerHTML = html;
            updateHistory(url, push);
            dispatchMounted(host);
        } catch (_) {
            window.location.href = url;
        } finally {
            host.classList.remove('is-loading');
        }
    }

    function bind(host) {
        if (!host || host.dataset.smartListadoBound === '1') {
            return;
        }
        host.dataset.smartListadoBound = '1';

        host.addEventListener('submit', (e) => {
            const form = e.target.closest('[data-smart-listado-filtros]');
            if (!form || !host.contains(form)) {
                return;
            }
            e.preventDefault();
            const url = new URL(form.action || window.location.href, window.location.href);
            const data = new FormData(form);
            url.search = '';
            data.forEach((value, key) => {
                if (String(value).trim() !== '') {
                    url.searchParams.set(key, String(value));
                }
            });
            url.searchParams.set('page', '1');
            loadIntoHost(host, url.toString(), true);
        });

        host.addEventListener('change', (e) => {
            const select = e.target.closest('[data-smart-listado-per-page]');
            if (!select || !host.contains(select)) {
                return;
            }
            const form = select.closest('form');
            if (form) {
                form.requestSubmit();
            }
        });

        host.addEventListener('click', (e) => {
            const pageLink = e.target.closest('[data-smart-listado-page]');
            if (pageLink && host.contains(pageLink)) {
                e.preventDefault();
                loadIntoHost(host, pageLink.href, true);
                return;
            }

            const reset = e.target.closest('[data-smart-listado-reset]');
            if (reset && host.contains(reset)) {
                e.preventDefault();
                loadIntoHost(host, reset.href, true);
            }
        });
    }

    function bindDocument() {
        const host = document.getElementById('personas-listado-host');
        if (host) {
            bind(host);
        }
    }

    window.SmartcsetListado = {
        bind,
        loadIntoHost,
        fetchPartial,
    };

    document.addEventListener('DOMContentLoaded', bindDocument);
    document.addEventListener('smartcset:listado:mounted', (e) => {
        const host = e.target;
        if (host && host.id === 'personas-listado-host') {
            host.dataset.smartListadoBound = '';
            bind(host);
        }
    });
})();
