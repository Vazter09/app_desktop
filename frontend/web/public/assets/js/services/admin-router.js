(function (global) {
    'use strict';
    const P = '/routers/admin/v1';
    global.SmartcsetAdminRouter = {
        cerrarSesion(idSesion) {
            return SmartcsetHttp.post(`${P}/sesiones/cerrar.php`, { id_sesion: idSesion });
        },
        guardarConfig(formData) {
            return SmartcsetHttp.post(`${P}/config/guardar.php`, formData);
        },
        restaurarConfig(section) {
            return SmartcsetHttp.post(`${P}/config/restaurar.php`, { section });
        },
        guardarConfigPersonas(formData) {
            return SmartcsetHttp.post(`${P}/personas/config_guardar.php`, formData);
        },
        restaurarConfigPersonas() {
            return SmartcsetHttp.post(`${P}/personas/config_restaurar.php`, {});
        },
        guardarPmtrosGrales(formData) {
            return SmartcsetHttp.post(`${P}/pmtros/guardar.php`, formData);
        },
        restaurarPmtrosGrales() {
            return SmartcsetHttp.post(`${P}/pmtros/restaurar.php`, {});
        },
    };
})(window);
