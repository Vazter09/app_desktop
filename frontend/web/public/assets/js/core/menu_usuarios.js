console.log('✓ menu_usuarios.js cargado correctamente');

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

    function esAdminSeleccionado() {
        if (!selUsr.value) return false;
        const opt = selUsr.options[selUsr.selectedIndex];
        return opt && opt.getAttribute('data-admin') === '1';
    }

    function aplicarModoAdministrador(esAdmin) {
        if (alertAdminFijo) {
            alertAdminFijo.classList.toggle('d-none', !esAdmin);
        }
        document.querySelectorAll('.check-logica').forEach(chk => {
            chk.disabled = esAdmin;
        });
        if (btnGuardarPermisos) {
            btnGuardarPermisos.disabled = esAdmin;
        }
    }

    console.log('Elementos del DOM encontrados:');
    console.log('  - sel_usuario:', selUsr ? '✓' : '✗');
    console.log('  - panel_permisos:', panelPermisos ? '✓' : '✗');
    console.log('  - hid_usuario:', hidUsr ? '✓' : '✗');
    console.log('  - form_perfiles:', form ? '✓' : '✗');

    // FUNCIÓN: Limpiar formulario
    function limpiarFormulario() {
        selUsr.value = '';
        hidUsr.value = '';
        panelPermisos.classList.add('ventana-bloqueada');
        aplicarModoAdministrador(false);

        document.querySelectorAll('.check-logica').forEach(chk => {
            chk.checked = false;
            chk.disabled = false;
        });

        selUsr.focus();
    }

    // FUNCIÓN: Cargar y mostrar menús asignados al usuario
    async function cargarMenusAsignados(idUsuario) {
        console.log('\n=== CARGAR MENÚS ASIGNADOS ===');
        console.log('ID Usuario:', idUsuario);
        
        try {
            const url = smartcsetUrl(`/routers/menus/v1/perfil/listar.php?usuario=${encodeURIComponent(idUsuario)}`);
            console.log('URL AJAX:', url);
            
            const response = await fetch(url, { credentials: 'include' });
            console.log('Response status:', response.status);
            
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
            console.log('=== RESPUESTA JSON COMPLETA ===');
            console.log(data);
            console.log('Status:', data.status);
            console.log('Source:', data.source);
            console.log('Cantidad de menús:', data.cantidad);
            console.log('Array de menús:', data.menusAsignados);

            if (data.status === 'success') {
                console.log('\n✓ Respuesta exitosa. Procesando...');

                const esAdmin = data.esAdministrador === true;
                aplicarModoAdministrador(esAdmin);

                // Desmarcar todos primero
                console.log('Desmarcando todos los checkboxes...');
                document.querySelectorAll('.check-logica').forEach(chk => {
                    chk.checked = false;
                });

                // Marcar solo los menús asignados
                console.log('\nMarcando menús asignados:');
                if (data.menusAsignados && data.menusAsignados.length > 0) {
                    data.menusAsignados.forEach(idMenu => {
                        const chk = document.getElementById(`chk_${idMenu}`);
                        if (chk) {
                            chk.checked = true;
                            console.log(`  ✓ Marcado: chk_${idMenu}`);
                        } else {
                            console.warn(`  ✗ NO ENCONTRADO: chk_${idMenu}`);
                        }
                    });
                } else {
                    console.log('  (Sin menús asignados)');
                }

                console.log('\n=== PROCESO COMPLETADO ===\n');
            } else {
                // Error - mostrar categorizado
                mostrarErrorCategorizado(data);
            }
        } catch (error) {
            const errorData = {
                status: 'error',
                message: 'Error crítico al cargar menús: ' + error.message,
                source: 'NETWORK',
                debug: error.toString()
            };
            mostrarErrorCategorizado(errorData);
            console.error('ERROR CRÍTICO:', error);
        }
    }

    // Al seleccionar usuario
    selUsr.addEventListener('change', async () => {
        console.log('=== CAMBIO DE USUARIO ===');
        console.log('Usuario seleccionado:', selUsr.value);
        
        if(selUsr.value !== "") {
            const nomUsuario = selUsr.options[selUsr.selectedIndex].text;
            console.log('Nombre del usuario:', nomUsuario);

            hidUsr.value = selUsr.value;
            panelPermisos.classList.remove('ventana-bloqueada');

            console.log('Panel desbloqueado. Llamando cargarMenusAsignados...');
            await cargarMenusAsignados(selUsr.value);
        } else {
            console.log('Usuario vacío. Bloqueando panel.');
            panelPermisos.classList.add('ventana-bloqueada');
            aplicarModoAdministrador(false);
            document.querySelectorAll('.check-logica').forEach(chk => {
                chk.checked = false;
                chk.disabled = false;
            });
        }
    });

    // Botón "Limpiar / Nuevo"
    const btnLimpiar = document.getElementById('btn_limpiar');
    if (btnLimpiar) {
        btnLimpiar.addEventListener('click', () => {
            console.log('=== LIMPIAR FORMULARIO ===');
            limpiarFormulario();
        });
    }

    // Lógica: Marcar padres cuando se marca un hijo
    document.querySelectorAll('.check-logica').forEach(chk => {
        chk.addEventListener('change', function() {
            if (this.checked) {
                // Encontrar la fila de este menú
                const fila = this.closest('tr');
                if (fila) {
                    // Obtener el ID del padre
                    const paddreId = fila.getAttribute('data-padre');
                    
                    console.log(`Menú marcado: ${this.value}, Padre: ${paddreId}`);
                    
                    // Marcar recursivamente todos los padres hacia arriba
                    let padreActual = paddreId;
                    while (padreActual && padreActual !== "0") {
                        const chkPadre = document.getElementById(`chk_${padreActual}`);
                        if (chkPadre) {
                            chkPadre.checked = true;
                            console.log(`  → Padre marcado automáticamente: ${padreActual}`);
                            
                            // Buscar el padre del padre
                            const filaPadre = document.querySelector(`tr[data-id-menu="${padreActual}"]`);
                            if (filaPadre) {
                                padreActual = filaPadre.getAttribute('data-padre');
                            } else {
                                padreActual = "0";
                            }
                        } else {
                            padreActual = "0";
                        }
                    }
                }
            }
        });
    });

    function mostrarErrorCategorizado(errorData) {
        console.error('Error en accesos:', errorData);
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

    // Guardar cambios
    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        if (esAdminSeleccionado()) {
            mostrarErrorCategorizado({
                status: 'error',
                message: 'Los administradores tienen acceso fijo a todo el catálogo.',
                source: 'VALIDATION'
            });
            return;
        }

        console.log('\n=== ENVIAR FORMULARIO ===');
        
        const formData = new FormData(form);
        const nomUsuario = selUsr.options[selUsr.selectedIndex].text;
        
        console.log('Usuario:', nomUsuario);
        console.log('ID Usuario:', selUsr.value);
        
        // Mostrar menús marcados
        const menusChecked = [];
        document.querySelectorAll('.check-logica:checked').forEach(chk => {
            menusChecked.push(chk.value);
        });
        console.log('Menús a guardar:', menusChecked);
        console.log('Total menús a guardar:', menusChecked.length);
        
        try {
            const response = await fetch(smartcsetUrl('/routers/menus/v1/perfil/guardar.php'), {
                method: 'POST',
                credentials: 'include',
                body: formData
            });

            const payload = await response.json();
            const data = payload.ok
                ? { status: 'success', message: payload.data?.message, cantidadGuardada: payload.data?.cantidadGuardada }
                : { status: 'error', message: payload.error || 'No se pudo guardar' };
            console.log('Respuesta del servidor:', data);
            console.log('Fuente del error:', data.source);

            if(data.status === 'success') {
                mostrarExito(data, nomUsuario);
                
                setTimeout(() => {
                    limpiarFormulario();
                }, 500);
            } else {
                mostrarErrorCategorizado(data);
            }
        } catch (error) {
            const errorData = {
                status: 'error',
                message: 'Error crítico de red o comunicación con el servidor. Verifique su conexión.',
                source: 'NETWORK',
                debug: error.message
            };
            mostrarErrorCategorizado(errorData);
            console.error('Error en submit:', error);
        }
    });
}

(window.smartcsetOnPageReady || function (fn) {
    document.addEventListener('DOMContentLoaded', fn);
})(initMenuUsuarios);