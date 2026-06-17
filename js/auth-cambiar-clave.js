// Bloquear navegación hacia atrás
history.pushState(null, null, location.href);
window.onpopstate = function () {
    history.go(1);
};

// Confirmación solo si hay cambios sin guardar
let hasChanges = false;
document.addEventListener('input', function (e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') {
        hasChanges = true;
    }
});
window.addEventListener('beforeunload', function (e) {
    if (hasChanges) {
        e.preventDefault();
        e.returnValue = '';
    }
});
document.addEventListener('submit', function () {
    hasChanges = false;
});
