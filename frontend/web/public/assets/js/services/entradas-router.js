(function (global) {
    'use strict';
    const P = '/routers/entradas/v1';
    global.SmartcsetEntradasRouter = {
        guardar(data) { return SmartcsetHttp.post(`${P}/guardar.php`, data); },
        eliminar(id) { return SmartcsetHttp.post(`${P}/eliminar.php`, { id_entrada: id }); },
    };
})(window);
