/**
 * Portería ingreso — mismas URLs que app móvil.
 */
(function (global) {
    'use strict';

    const PREFIX = '/routers/porteria/v1/ingreso';

    global.SmartcsetIngresoRouter = {
        consultar(documento, tipoDoc = 'CC') {
            return SmartcsetHttp.get(`${PREFIX}/consultar.php`, { documento, tipo_doc: tipoDoc });
        },
        registrar(payload) {
            return SmartcsetHttp.post(`${PREFIX}/registrar.php`, payload);
        },
        listarHoy() {
            return SmartcsetHttp.get(`${PREFIX}/hoy.php`);
        },
    };
})(window);
