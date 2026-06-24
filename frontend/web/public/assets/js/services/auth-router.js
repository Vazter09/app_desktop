(function (global) {
    'use strict';
    const P = '/routers/auth/v1';
    global.SmartcsetAuthRouter = {
        login(usuario, clave) {
            return SmartcsetHttp.post(`${P}/login.php`, { usuario, clave });
        },
        recuperar(data) {
            return SmartcsetHttp.post(`${P}/recuperar.php`, data);
        },
        cambiarClave(passAntigua, passNueva) {
            return SmartcsetHttp.post(`${P}/cambiar_clave.php`, { pass_antigua: passAntigua, pass_nueva: passNueva });
        },
    };
})(window);
