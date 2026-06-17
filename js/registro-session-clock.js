/**
 * Reloj de sesión en vivo (módulo registro).
 */
(function () {
    var clock = document.getElementById('session-clock');
    if (!clock) {
        return;
    }

    var formatter = new Intl.DateTimeFormat('es-CO', {
        hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
        timeZone: 'America/Bogota'
    });

    function updateClock() {
        clock.textContent = formatter.format(new Date());
    }

    updateClock();
    setInterval(updateClock, 1000);
})();
