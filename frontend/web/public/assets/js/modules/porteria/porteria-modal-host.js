/**
 * Portería — ancla modales en body y limpia huérfanos tras navegación SPA.
 */
(function (global) {
    'use strict';

    const MODAL_IDS = ['ingresoFormModal', 'salidaFormModal', 'documentModal'];

    /**
     * @param {string} id
     * @returns {HTMLElement|null}
     */
    function ensureModalOnBody(id) {
        const main = document.querySelector('main.main-content');
        const inMain = main ? main.querySelector(`#${id}`) : null;
        const onBody = Array.from(document.querySelectorAll(`body > #${CSS.escape(id)}`));

        // SPA: nueva copia en main → descartar instancias viejas en body
        if (inMain) {
            onBody.forEach((el) => {
                global.bootstrap?.Modal?.getInstance(el)?.dispose();
                el.remove();
            });
            if (inMain.parentElement !== document.body) {
                document.body.appendChild(inMain);
            }
            return inMain;
        }

        // Ya anclado en body (uso normal tras el primer prepare)
        if (onBody.length > 0) {
            return onBody[0];
        }

        const el = document.getElementById(id);
        if (!el) {
            return null;
        }

        if (el.parentElement !== document.body) {
            document.body.appendChild(el);
        }

        return el;
    }

    function cleanupStuckModalState() {
        const openModals = document.querySelectorAll('.modal.show');
        if (openModals.length > 0) {
            return;
        }
        document.querySelectorAll('.modal-backdrop').forEach((el) => el.remove());
        document.body.classList.remove('modal-open');
        document.body.style.removeProperty('overflow');
        document.body.style.removeProperty('padding-right');
    }

    function preparePorteriaModals() {
        cleanupStuckModalState();
        MODAL_IDS.forEach((id) => ensureModalOnBody(id));
    }

    /**
     * @param {string} id
     */
    function showModal(id) {
        const el = ensureModalOnBody(id);
        if (!el || !global.bootstrap?.Modal) {
            return null;
        }
        const instance = global.bootstrap.Modal.getOrCreateInstance(el);
        instance.show();
        return instance;
    }

    global.PorteriaModalHost = {
        ensureModalOnBody,
        preparePorteriaModals,
        showModal,
    };

    if (typeof global.smartcsetOnPageReady === 'function') {
        global.smartcsetOnPageReady(preparePorteriaModals);
    } else {
        document.addEventListener('DOMContentLoaded', preparePorteriaModals);
    }
})(window);
