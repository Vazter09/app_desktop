(function (global) {
    'use strict';
    const P = '/routers/usuarios/v1';
    global.SmartcsetUsuariosRouter = {
        guardar(data) { return SmartcsetHttp.post(`${P}/guardar.php`, data); },
        toggleEstado(id, nuevoEstado) {
            return SmartcsetHttp.post(`${P}/toggle_estado.php`, { id_usuario: id, nuevo_estado: nuevoEstado });
        },
    };
})(window);
