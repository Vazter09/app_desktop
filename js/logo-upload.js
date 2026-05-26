/**
 * File drop — logo en configuración admin (un solo archivo).
 */
(function () {
    const root = document.getElementById('logo-file-drop');
    if (!root) return;

    const zone = root.querySelector('.file-drop__zone');
    const input = root.querySelector('.file-drop__input');
    const trigger = root.querySelector('.file-drop__btn-select');
    const previewWrap = root.querySelector('.file-drop__preview');
    const previewImg = root.querySelector('.file-drop__preview-img');
    const pathLabel = root.querySelector('.file-drop__path');
    const statusEl = root.querySelector('.file-drop__status');

    if (!zone || !input) return;

    const maxFiles = Math.max(
        1,
        parseInt(root.dataset.maxFiles || input.dataset.maxFiles || '1', 10) || 1
    );
    const allowed = ['image/png', 'image/jpeg', 'image/gif', 'image/webp'];
    const maxBytes = 5 * 1024 * 1024;

    input.removeAttribute('multiple');

    const openPicker = () => input.click();

    const setStatus = (message, visible) => {
        if (!statusEl) return;
        statusEl.textContent = message;
        statusEl.classList.toggle('is-visible', visible);
    };

    const showPreview = (src) => {
        if (!previewImg || !src) return;
        previewImg.src = src;
        previewImg.classList.remove('d-none');
        previewWrap?.classList.remove('is-empty');
    };

    const rejectMultiple = (count) => {
        if (count <= maxFiles) return false;
        setStatus('Solo se permite 1 archivo. Seleccione una sola imagen.', true);
        input.value = '';
        return true;
    };

    const handleFile = (file) => {
        if (!file) return;

        if (!allowed.includes(file.type)) {
            setStatus('Formato no permitido. Use PNG, JPG, GIF o WebP.', true);
            return;
        }

        if (file.size > maxBytes) {
            setStatus('El archivo supera el límite de 5 MB.', true);
            return;
        }

        setStatus('', false);

        const reader = new FileReader();
        reader.onload = (e) => showPreview(e.target?.result || '');
        reader.readAsDataURL(file);

        if (pathLabel) {
            pathLabel.textContent = file.name + ' — se guardará al pulsar «Guardar configuración».';
        }
    };

    trigger?.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        openPicker();
    });

    zone.addEventListener('click', (e) => {
        if (e.target.closest('.file-drop__btn-select')) return;
        openPicker();
    });

    zone.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            openPicker();
        }
    });

    input.addEventListener('change', () => {
        const files = input.files;
        if (!files?.length) return;
        if (rejectMultiple(files.length)) return;
        handleFile(files[0]);
    });

    ['dragenter', 'dragover'].forEach((ev) => {
        zone.addEventListener(ev, (e) => {
            e.preventDefault();
            e.stopPropagation();
            zone.classList.add('is-dragover');
        });
    });

    ['dragleave', 'drop'].forEach((ev) => {
        zone.addEventListener(ev, (e) => {
            e.preventDefault();
            e.stopPropagation();
            zone.classList.remove('is-dragover');
        });
    });

    zone.addEventListener('drop', (e) => {
        const dropped = e.dataTransfer?.files;
        if (!dropped?.length) return;
        if (rejectMultiple(dropped.length)) return;
        const file = dropped[0];
        const dt = new DataTransfer();
        dt.items.add(file);
        input.files = dt.files;
        handleFile(file);
    });
})();
