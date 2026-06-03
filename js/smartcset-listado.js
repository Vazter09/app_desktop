/**
 * Comportamiento reutilizable de listados: filtros GET y paginación vía AJAX partial.
 * El contenedor debe tener id personas-listado-host (o data-smart-listado-host).
 */
(function () {
    const PARTIAL_PARAM = 'partial';
    const PARTIAL_VALUE = '1';
    const SEARCH_DEBOUNCE_MS = 250;
    const debounceTimers = new WeakMap();

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

    function isFiltroTextInput(el) {
        if (!el || el.tagName !== 'INPUT') {
            return false;
        }
        const type = (el.type || 'text').toLowerCase();
        if (type === 'hidden' || type === 'submit' || type === 'button' || type === 'checkbox' || type === 'radio') {
            return false;
        }
        return type === 'text' || type === 'search' || type === '';
    }

    function captureFiltroFocus(host) {
        const active = document.activeElement;
        const form = active?.closest?.('[data-smart-listado-filtros]');
        if (!form || !host.contains(form) || !isFiltroTextInput(active)) {
            return null;
        }
        const name = active.getAttribute('name');
        if (!name) {
            return null;
        }
        return {
            name,
            selectionStart: typeof active.selectionStart === 'number' ? active.selectionStart : null,
            selectionEnd: typeof active.selectionEnd === 'number' ? active.selectionEnd : null,
        };
    }

    function restoreFiltroFocus(host, state) {
        if (!state?.name) {
            return;
        }
        const form = host.querySelector('[data-smart-listado-filtros]');
        if (!form) {
            return;
        }
        const input = form.querySelector(`input[name="${CSS.escape(state.name)}"]`);
        if (!input || !isFiltroTextInput(input)) {
            return;
        }
        input.focus({ preventScroll: true });
        if (state.selectionStart !== null && typeof input.setSelectionRange === 'function') {
            const len = input.value.length;
            const start = Math.min(state.selectionStart, len);
            const end = Math.min(state.selectionEnd ?? state.selectionStart, len);
            try {
                input.setSelectionRange(start, end);
            } catch (_) {
                /* input no editable */
            }
        }
    }

    async function loadIntoHost(host, url, push) {
        const focusState = captureFiltroFocus(host);
        host.classList.add('is-loading');
        try {
            const html = await fetchPartial(url);
            host.innerHTML = html;
            restoreFiltroFocus(host, focusState);
            updateHistory(url, push);
            dispatchMounted(host);
        } catch (_) {
            window.location.href = url;
        } finally {
            host.classList.remove('is-loading');
        }
    }

    function clearSearchDebounce(host) {
        const timer = debounceTimers.get(host);
        if (timer) {
            clearTimeout(timer);
            debounceTimers.delete(host);
        }
    }

    function applyFiltrosForm(form, host) {
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
            clearSearchDebounce(host);
            applyFiltrosForm(form, host);
        });

        host.addEventListener('input', (e) => {
            const form = e.target.closest('[data-smart-listado-filtros]');
            if (!form || !host.contains(form)) {
                return;
            }
            const textInput = e.target.closest('input[type="text"], input[type="search"], input:not([type])');
            if (!textInput || textInput.type === 'hidden' || !form.contains(textInput)) {
                return;
            }
            clearSearchDebounce(host);
            debounceTimers.set(host, setTimeout(() => {
                debounceTimers.delete(host);
                applyFiltrosForm(form, host);
            }, SEARCH_DEBOUNCE_MS));
        });

        host.addEventListener('change', (e) => {
            const perPage = e.target.closest('[data-smart-listado-per-page]');
            if (perPage && host.contains(perPage)) {
                const form = perPage.closest('form');
                if (form) {
                    form.requestSubmit();
                }
                return;
            }

            const form = e.target.closest('[data-smart-listado-filtros]');
            if (!form || !host.contains(form)) {
                return;
            }
            const select = e.target.closest('select');
            if (select && form.contains(select)) {
                clearSearchDebounce(host);
                applyFiltrosForm(form, host);
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
