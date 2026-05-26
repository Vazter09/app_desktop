/**
 * SmartCSET — confirmaciones con Bootstrap Modal (reemplazo de confirm() nativo)
 */
(function (global) {
    'use strict';

    let modalEl = null;
    let modalInstance = null;
    let pendingResolve = null;
    let eventsWired = false;

    function ensureModal() {
        if (modalEl) return modalEl;

        modalEl = document.getElementById('smartConfirmModal');
        if (modalEl) {
            modalInstance = bootstrap.Modal.getOrCreateInstance(modalEl, { backdrop: 'static', keyboard: true });
            wireModalEvents();
            return modalEl;
        }

        const wrapper = document.createElement('div');
        wrapper.innerHTML = `
<div class="modal fade" id="smartConfirmModal" tabindex="-1" aria-labelledby="smartConfirmTitle" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content border-0 shadow smart-confirm-content">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title d-flex align-items-center gap-2" id="smartConfirmTitle">
                    <i class="bi bi-question-circle-fill text-warning" id="smartConfirmIcon"></i>
                    <span id="smartConfirmTitleText">Confirmar</span>
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body pt-2 pb-3" id="smartConfirmMessage"></div>
            <div class="modal-footer border-0 pt-0 gap-2">
                <button type="button" class="btn btn-light btn-sm px-3" data-bs-dismiss="modal" id="smartConfirmCancel">Cancelar</button>
                <button type="button" class="btn btn-sm px-3" id="smartConfirmOk">Aceptar</button>
            </div>
        </div>
    </div>
</div>`;
        modalEl = wrapper.firstElementChild;
        document.body.appendChild(modalEl);
        modalInstance = bootstrap.Modal.getOrCreateInstance(modalEl, { backdrop: 'static', keyboard: true });
        wireModalEvents();
        return modalEl;
    }

    function wireModalEvents() {
        if (eventsWired) return;
        eventsWired = true;

        const btnOk = document.getElementById('smartConfirmOk');
        const btnCancel = document.getElementById('smartConfirmCancel');

        btnOk.addEventListener('click', () => {
            const resolve = pendingResolve;
            pendingResolve = null;
            modalInstance.hide();
            if (resolve) resolve(true);
        });

        modalEl.addEventListener('hidden.bs.modal', () => {
            if (pendingResolve) {
                const resolve = pendingResolve;
                pendingResolve = null;
                resolve(false);
            }
        });
    }

    /**
     * @param {{ title?: string, message: string, confirmText?: string, cancelText?: string, variant?: 'danger'|'primary'|'warning' }} options
     * @returns {Promise<boolean>}
     */
    function show(options) {
        if (typeof bootstrap === 'undefined' || !bootstrap.Modal) {
            return Promise.resolve(global.confirm(options.message || '¿Continuar?'));
        }

        ensureModal();

        const title = options.title || 'Confirmar acción';
        const message = options.message || '¿Desea continuar?';
        const confirmText = options.confirmText || 'Aceptar';
        const cancelText = options.cancelText || 'Cancelar';
        const variant = options.variant || 'danger';

        document.getElementById('smartConfirmTitleText').textContent = title;
        document.getElementById('smartConfirmMessage').textContent = message;
        document.getElementById('smartConfirmCancel').textContent = cancelText;

        const btnOk = document.getElementById('smartConfirmOk');
        btnOk.textContent = confirmText;
        btnOk.className = 'btn btn-sm px-3';
        if (variant === 'primary') {
            btnOk.classList.add('btn-corporativo');
        } else if (variant === 'warning') {
            btnOk.classList.add('btn-warning', 'text-dark');
        } else {
            btnOk.classList.add('btn-danger');
        }

        const icon = document.getElementById('smartConfirmIcon');
        icon.className = 'bi ';
        if (variant === 'primary') {
            icon.classList.add('bi-info-circle-fill', 'text-primary');
        } else if (variant === 'warning') {
            icon.classList.add('bi-exclamation-triangle-fill', 'text-warning');
        } else {
            icon.classList.add('bi-trash3-fill', 'text-danger');
        }

        return new Promise((resolve) => {
            pendingResolve = resolve;
            modalInstance.show();
            modalEl.addEventListener('shown.bs.modal', () => btnOk.focus(), { once: true });
        });
    }

    function getSubmitter(form, event) {
        if (event && event.submitter) {
            return event.submitter;
        }
        return form.querySelector('button[type="submit"][name], input[type="submit"][name]');
    }

    /** Reenvía el formulario incluyendo el name/value del botón (p. ej. btn_eliminar). */
    function submitFormConfirmed(form, submitter) {
        form.dataset.smartConfirmSkip = '1';

        if (typeof form.requestSubmit === 'function') {
            form.requestSubmit(submitter || undefined);
            return;
        }

        let tempHidden = null;
        if (submitter && submitter.name) {
            tempHidden = document.createElement('input');
            tempHidden.type = 'hidden';
            tempHidden.name = submitter.name;
            tempHidden.value = submitter.value || '1';
            form.appendChild(tempHidden);
        }

        form.submit();

        if (tempHidden) {
            tempHidden.remove();
        }
    }

    function bindForms() {
        document.querySelectorAll('form[data-smart-confirm]').forEach((form) => {
            if (form.dataset.smartConfirmBound === '1') return;
            form.dataset.smartConfirmBound = '1';

            form.addEventListener('submit', async (e) => {
                if (form.dataset.smartConfirmSkip === '1') {
                    delete form.dataset.smartConfirmSkip;
                    return;
                }

                e.preventDefault();
                e.stopPropagation();

                const submitter = getSubmitter(form, e);

                const ok = await show({
                    title: form.dataset.smartConfirmTitle || 'Confirmar',
                    message: form.dataset.smartConfirmMessage || '¿Desea continuar?',
                    confirmText: form.dataset.smartConfirmOk || 'Aceptar',
                    cancelText: form.dataset.smartConfirmCancel || 'Cancelar',
                    variant: form.dataset.smartConfirmVariant || 'danger'
                });

                if (ok) {
                    submitFormConfirmed(form, submitter);
                }
            });
        });
    }

    global.SmartConfirm = { show, bindForms };

    document.addEventListener('DOMContentLoaded', bindForms);
})(window);
