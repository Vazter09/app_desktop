(function (global) {
    'use strict';
    const P = '/routers/menus/v1';
    global.SmartcsetMenusRouter = {
        guardar(data) { return SmartcsetHttp.post(`${P}/guardar.php`, data); },
        eliminar(id) { return SmartcsetHttp.post(`${P}/eliminar.php`, { id_menu: id }); },
        copiarPerfil(origen, destino) {
            return SmartcsetHttp.post(`${P}/perfil/copiar.php`, { usuario_origen: origen, usuario_destino: destino });
        },
        asignarPermiso(idUsuario, idMenu) {
            return SmartcsetHttp.post(`${P}/permiso/asignar.php`, { id_usuario: idUsuario, id_menu: idMenu });
        },
    };
})(window);
