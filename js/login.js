document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.querySelector('#loginForm');
    
    loginForm.addEventListener('submit', function(e) {
        const pass = document.querySelector('input[name="txt_clave"]').value;
        
        if (pass.length < 12) {
            e.preventDefault();
            if (typeof SmartToast !== 'undefined') {
                SmartToast.warning('La contraseña debe tener al menos 12 caracteres.', 'Validación');
            } else {
                alert('La contraseña debe tener al menos 12 caracteres.');
            }
        }
    });
});