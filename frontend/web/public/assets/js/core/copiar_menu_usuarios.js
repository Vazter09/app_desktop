/**
 * Copiar perfil de menús entre usuarios (compatible con navegación SPA).
 */
(function () {
    let copiarMenuAbort = null;

    function initCopiarMenuUsuarios() {
        const selOrigen = document.getElementById('sel_origen');
        const selDestino = document.getElementById('sel_destino');
        const form = document.getElementById('form_copiar');
        const btnCopiar = document.getElementById('btn_copiar');

        if (!selOrigen || !selDestino || !form || !btnCopiar) {
            return;
        }

        if (copiarMenuAbort) {
            copiarMenuAbort.abort();
        }
        copiarMenuAbort = new AbortController();
        const { signal } = copiarMenuAbort;

        function validarBoton() {
            const origen = selOrigen.value;
            const destino = selDestino.value;
            const optOrigen = selOrigen.options[selOrigen.selectedIndex];
            const optDestino = selDestino.options[selDestino.selectedIndex];
            const esAdmin = (optOrigen && optOrigen.getAttribute('data-admin') === '1')
                || (optDestino && optDestino.getAttribute('data-admin') === '1');

            btnCopiar.disabled = !origen || !destino || origen === destino || esAdmin;
            btnCopiar.title = esAdmin
                ? 'No se puede copiar el perfil del usuario administrador.'
                : '';
        }

        function mostrarErrorCategorizado(errorData) {
            if (typeof SmartToast !== 'undefined') {
                SmartToast.fromErrorData(errorData);
            } else {
                alert(errorData.message || 'Error desconocido');
            }
        }

        function mostrarExito(data) {
            if (typeof SmartToast !== 'undefined') {
                SmartToast.fromSuccessData(data);
            } else {
                alert(data.message || 'Operación completada');
            }
        }

        selOrigen.addEventListener('change', validarBoton, { signal });
        selDestino.addEventListener('change', validarBoton, { signal });

        form.addEventListener('submit', async (e) => {
            e.preventDefault();

            const usuarioOrigen = selOrigen.value;
            const usuarioDestino = selDestino.value;

            if (!usuarioOrigen || !usuarioDestino) {
                return mostrarErrorCategorizado({
                    source: 'VALIDATION',
                    message: 'Debe seleccionar ambos usuarios (origen y destino).',
                });
            }

            if (usuarioOrigen === usuarioDestino) {
                return mostrarErrorCategorizado({
                    source: 'VALIDATION',
                    message: 'El usuario origen y destino no pueden ser el mismo.',
                });
            }

            let confirmar = true;
            if (typeof SmartConfirm !== 'undefined') {
                confirmar = await SmartConfirm.show({
                    title: 'Copiar perfil de menús',
                    message: '¿Reemplazar los menús del usuario destino con los del usuario origen?',
                    confirmText: 'Copiar',
                    cancelText: 'Cancelar',
                    variant: 'warning',
                });
            }
            if (!confirmar) {
                return;
            }

            const formData = new FormData(form);

            try {
                const response = await fetch(smartcsetUrl('/routers/menus/v1/perfil/copiar.php'), {
                    method: 'POST',
                    credentials: 'include',
                    body: formData,
                    signal,
                });

                const payload = await response.json();
                const data = payload.ok
                    ? { status: 'success', message: payload.data?.message, copiados: payload.data?.copiados }
                    : { status: 'error', message: payload.error || 'Error al copiar' };

                if (data.status === 'success') {
                    mostrarExito(data);
                    selOrigen.value = '';
                    selDestino.value = '';
                    validarBoton();
                } else {
                    mostrarErrorCategorizado(data);
                }
            } catch (error) {
                if (error.name === 'AbortError') {
                    return;
                }
                mostrarErrorCategorizado({
                    source: 'NETWORK',
                    message: 'Error de comunicación con el servidor.',
                    debug: error.message,
                });
            }
        }, { signal });

        validarBoton();
    }

    window.smartcsetInitCopiarMenuUsuarios = initCopiarMenuUsuarios;

    (window.smartcsetOnPageReady || function (fn) {
        document.addEventListener('DOMContentLoaded', fn);
    })(initCopiarMenuUsuarios);
})();
