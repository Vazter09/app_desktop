/**
 * Accesos — asignación de menús por usuario (compatible con navegación SPA).
 */
(function () {
    let menuUsuariosAbort = null;

    function initMenuUsuarios() {
        const selUsr = document.getElementById('sel_usuario');
        const panelPermisos = document.getElementById('panel_permisos');
        const alertAdminFijo = document.getElementById('alert_admin_fijo');
        const btnGuardarPermisos = document.getElementById('btn_guardar_permisos');
        const hidUsr = document.getElementById('hid_usuario');
        const form = document.getElementById('form_perfiles');

        if (!selUsr || !panelPermisos || !form) {
            return;
        }

        if (menuUsuariosAbort) {
            menuUsuariosAbort.abort();
        }
        menuUsuariosAbort = new AbortController();
        const { signal } = menuUsuariosAbort;

        function esAdminSeleccionado() {
            if (!selUsr.value) {
                return false;
            }
            const opt = selUsr.options[selUsr.selectedIndex];
            return opt && opt.getAttribute('data-admin') === '1';
        }

        function aplicarModoAdministrador(esAdmin) {
            if (alertAdminFijo) {
                alertAdminFijo.classList.toggle('d-none', !esAdmin);
            }
            panelPermisos.querySelectorAll('.check-logica').forEach((chk) => {
                chk.disabled = esAdmin;
            });
            if (btnGuardarPermisos) {
                btnGuardarPermisos.disabled = esAdmin;
            }
        }

        function limpiarFormulario() {
            selUsr.value = '';
            hidUsr.value = '';
            panelPermisos.classList.add('ventana-bloqueada');
            aplicarModoAdministrador(false);
            panelPermisos.querySelectorAll('.check-logica').forEach((chk) => {
                chk.checked = false;
                chk.disabled = false;
            });
            selUsr.focus();
        }

        function mostrarErrorCategorizado(errorData) {
            if (typeof SmartToast !== 'undefined') {
                SmartToast.fromErrorData(errorData);
            } else {
                alert(errorData.message || 'Error desconocido');
            }
        }

        function mostrarExito(successData, nomUsuario) {
            if (typeof SmartToast !== 'undefined') {
                SmartToast.fromSuccessData(successData, `Accesos actualizados para: ${nomUsuario}`);
            } else {
                alert(successData.message || 'Operación completada');
            }
        }

        async function cargarMenusAsignados(idUsuario) {
            try {
                const url = smartcsetUrl(
                    `/routers/menus/v1/perfil/listar.php?usuario=${encodeURIComponent(idUsuario)}`
                );
                const response = await fetch(url, { credentials: 'include', signal });
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const payload = await response.json();
                const data = payload.ok
                    ? {
                        status: 'success',
                        menusAsignados: payload.data?.menus || [],
                        esAdministrador: Boolean(payload.data?.admin),
                    }
                    : { status: 'error', message: payload.error || 'Error al cargar menús' };

                if (data.status !== 'success') {
                    mostrarErrorCategorizado(data);
                    return;
                }

                const esAdmin = data.esAdministrador === true;
                aplicarModoAdministrador(esAdmin);

                panelPermisos.querySelectorAll('.check-logica').forEach((chk) => {
                    chk.checked = false;
                });

                if (data.menusAsignados && data.menusAsignados.length > 0) {
                    data.menusAsignados.forEach((idMenu) => {
                        const chk = document.getElementById(`chk_${idMenu}`);
                        if (chk) {
                            chk.checked = true;
                        }
                    });
                }
            } catch (error) {
                if (error.name === 'AbortError') {
                    return;
                }
                mostrarErrorCategorizado({
                    status: 'error',
                    message: 'Error al cargar menús: ' + error.message,
                    source: 'NETWORK',
                });
            }
        }

        async function onUsuarioSeleccionado() {
            if (selUsr.value !== '') {
                hidUsr.value = selUsr.value;
                panelPermisos.classList.remove('ventana-bloqueada');
                await cargarMenusAsignados(selUsr.value);
            } else {
                panelPermisos.classList.add('ventana-bloqueada');
                aplicarModoAdministrador(false);
                panelPermisos.querySelectorAll('.check-logica').forEach((chk) => {
                    chk.checked = false;
                    chk.disabled = false;
                });
            }
        }

        selUsr.addEventListener('change', onUsuarioSeleccionado, { signal });

        const btnLimpiar = document.getElementById('btn_limpiar');
        if (btnLimpiar) {
            btnLimpiar.addEventListener('click', limpiarFormulario, { signal });
        }

        panelPermisos.querySelectorAll('.check-logica').forEach((chk) => {
            chk.addEventListener('change', function onCheckChange() {
                if (!this.checked) {
                    return;
                }
                const fila = this.closest('tr');
                if (!fila) {
                    return;
                }
                let padreActual = fila.getAttribute('data-padre');
                while (padreActual && padreActual !== '0') {
                    const chkPadre = document.getElementById(`chk_${padreActual}`);
                    if (chkPadre) {
                        chkPadre.checked = true;
                        const filaPadre = panelPermisos.querySelector(
                            `tr[data-id-menu="${padreActual}"]`
                        );
                        padreActual = filaPadre ? filaPadre.getAttribute('data-padre') : '0';
                    } else {
                        padreActual = '0';
                    }
                }
            }, { signal });
        });

        form.addEventListener('submit', async (e) => {
            e.preventDefault();

            if (esAdminSeleccionado()) {
                mostrarErrorCategorizado({
                    status: 'error',
                    message: 'Los administradores tienen acceso fijo a todo el catálogo.',
                    source: 'VALIDATION',
                });
                return;
            }

            const formData = new FormData(form);
            const nomUsuario = selUsr.options[selUsr.selectedIndex].text;

            try {
                const response = await fetch(smartcsetUrl('/routers/menus/v1/perfil/guardar.php'), {
                    method: 'POST',
                    credentials: 'include',
                    body: formData,
                    signal,
                });

                const payload = await response.json();
                const data = payload.ok
                    ? {
                        status: 'success',
                        message: payload.data?.message,
                        cantidadGuardada: payload.data?.cantidadGuardada,
                    }
                    : { status: 'error', message: payload.error || 'No se pudo guardar' };

                if (data.status === 'success') {
                    mostrarExito(data, nomUsuario);
                    setTimeout(limpiarFormulario, 500);
                } else {
                    mostrarErrorCategorizado(data);
                }
            } catch (error) {
                if (error.name === 'AbortError') {
                    return;
                }
                mostrarErrorCategorizado({
                    status: 'error',
                    message: 'Error de comunicación con el servidor.',
                    source: 'NETWORK',
                    debug: error.message,
                });
            }
        }, { signal });

        if (selUsr.value) {
            onUsuarioSeleccionado();
        } else {
            panelPermisos.classList.add('ventana-bloqueada');
            aplicarModoAdministrador(false);
        }
    }

    window.smartcsetInitMenuUsuarios = initMenuUsuarios;

    (window.smartcsetOnPageReady || function (fn) {
        document.addEventListener('DOMContentLoaded', fn);
    })(initMenuUsuarios);
})();
