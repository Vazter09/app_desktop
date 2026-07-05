/**
 * SmartCSET — aviso de expiración de sesión.
 * Muestra modal con cuenta regresiva cuando quedan `warnSeg` segundos.
 * Se renueva automáticamente si el usuario hace click en "Seguir activo".
 * Requiere: Bootstrap 5, #smartcset-sesion-presencia con data-session-timeout y data-login-url.
 */
(function () {
    'use strict';

    var cfg = document.getElementById('smartcset-sesion-presencia');
    if (!cfg) { return; }

    var timeoutSeg = parseInt(cfg.getAttribute('data-session-timeout') || '1800', 10);
    var warnSeg    = 120;
    var loginUrl   = cfg.getAttribute('data-login-url') || '/';
    var heartbeatUrl = cfg.getAttribute('data-heartbeat-url') || '';

    if (timeoutSeg <= warnSeg || !heartbeatUrl) { return; }

    var modalEl  = document.getElementById('smartcsetSesionWarningModal');
    if (!modalEl) { return; }

    var bsModal     = new bootstrap.Modal(modalEl, { backdrop: 'static', keyboard: false });
    var elContador  = document.getElementById('sesion-warning-contador');
    var btnRenovar  = document.getElementById('sesion-warning-renovar');

    var lastTouch    = Date.now();
    var modalVisible = false;
    var countdown    = warnSeg;
    var tickTimer    = null;

    function formatContador(seg) {
        var m = Math.floor(seg / 60);
        var s = seg % 60;
        return m > 0 ? m + ':' + (s < 10 ? '0' : '') + s : seg + 's';
    }

    function actualizarContador() {
        if (elContador) {
            elContador.textContent = formatContador(countdown);
        }
    }

    function cerrarModal() {
        if (!modalVisible) { return; }
        clearInterval(tickTimer);
        tickTimer    = null;
        modalVisible = false;
        bsModal.hide();
    }

    function mostrarModal(segsRestantes) {
        if (modalVisible) { return; }
        modalVisible = true;
        countdown    = Math.max(1, Math.floor(segsRestantes));
        actualizarContador();
        bsModal.show();

        tickTimer = setInterval(function () {
            countdown--;
            actualizarContador();
            if (countdown <= 0) {
                clearInterval(tickTimer);
                window.location.href = loginUrl + '?sesion=invalida';
            }
        }, 1000);
    }

    function renovarSesion() {
        var body = new FormData();
        body.append('ult_ruta', window.location.pathname || '');

        fetch(heartbeatUrl, {
            method: 'POST',
            body: body,
            credentials: 'same-origin',
            headers: { Accept: 'application/json' }
        })
        .then(function (res) {
            if (res.ok) {
                document.dispatchEvent(new CustomEvent('smartcset:sesion-touch'));
            } else {
                window.location.href = loginUrl + '?sesion=invalida';
            }
        })
        .catch(function () {
            window.location.href = loginUrl + '?sesion=invalida';
        });
    }

    // Escucha el evento que emite smartcset-presencia.js tras cada ping exitoso
    document.addEventListener('smartcset:sesion-touch', function () {
        lastTouch = Date.now();
        cerrarModal();
    });

    // Revisar cada segundo si corresponde mostrar el aviso
    setInterval(function () {
        var elapsed   = (Date.now() - lastTouch) / 1000;
        var restantes = timeoutSeg - elapsed;

        if (restantes <= 0) {
            cerrarModal();
            window.location.href = loginUrl + '?sesion=invalida';
            return;
        }

        if (!modalVisible && restantes <= warnSeg) {
            mostrarModal(restantes);
        }
    }, 1000);

    if (btnRenovar) {
        btnRenovar.addEventListener('click', renovarSesion);
    }
})();
