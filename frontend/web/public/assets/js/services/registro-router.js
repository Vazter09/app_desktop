(function (global) {
    'use strict';
    const P = '/routers/registro/v1';
    global.SmartcsetRegistroRouter = {
        login(usuario, clave) {
            return SmartcsetHttp.post(`${P}/login.php`, { usuario, clave });
        },
        guardar(formData) {
            return SmartcsetHttp.post(`${P}/forms/guardar.php`, formData);
        },
        buscarAprendiz(idPersona, idTipoDocum) {
            const params = { id_persona: idPersona };
            if (idTipoDocum) {
                params.id_tipo_docum = idTipoDocum;
            }
            return SmartcsetHttp.get(`${P}/aprendiz/buscar.php`, params);
        },
        ciudades(idDpto) {
            return SmartcsetHttp.get(`${P}/ciudades.php`, { id_dpto: idDpto });
        },
    };
})(window);
