(function (global) {
    'use strict';

    const P = '/routers/instructor/v1';

    global.SmartcsetInstructorRouter = {
        listarFichas() {
            return SmartcsetHttp.get(`${P}/fichas/listar.php`);
        },
        listarAsistencia(idFicha, params = {}) {
            return SmartcsetHttp.get(`${P}/asistencia/listar.php`, Object.assign({ id_ficha: idFicha }, params));
        },
        resumenDashboard(fecha) {
            const params = fecha ? { fecha } : {};
            return SmartcsetHttp.get(`${P}/dashboard/resumen.php`, params);
        },
        registrarAsistencia(payload) {
            return SmartcsetHttp.post(`${P}/asistencia/registrar.php`, payload);
        },
        actualizarAsistencia(payload) {
            return SmartcsetHttp.put(`${P}/asistencia/actualizar.php`, payload);
        },
    };
})(window);
