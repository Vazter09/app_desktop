/**
 * Acordeón de formularios del módulo registro (vanilla JS).
 * Toggle .is-open en .registro-accordion-item; sincroniza aria-expanded.
 */
(function () {
    'use strict';

    function syncTriggerAria(item) {
        var trigger = item.querySelector(':scope > .registro-accordion-trigger');
        if (!trigger) {
            return;
        }
        trigger.setAttribute('aria-expanded', item.classList.contains('is-open') ? 'true' : 'false');
    }

    function initAccordion(root) {
        root.querySelectorAll('.registro-accordion-item').forEach(syncTriggerAria);

        root.addEventListener('click', function (e) {
            var trigger = e.target.closest('.registro-accordion-trigger');
            if (!trigger || !root.contains(trigger)) {
                return;
            }

            var item = trigger.closest('.registro-accordion-item');
            if (!item || item.closest('.registro-accordion') !== root) {
                return;
            }

            item.classList.toggle('is-open');
            syncTriggerAria(item);
        });
    }

    function boot() {
        document.querySelectorAll('.registro-accordion').forEach(initAccordion);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', boot);
    } else {
        boot();
    }
})();
