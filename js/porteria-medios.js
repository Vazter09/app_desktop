/**
 * Modo escáner (foco en documento) y modo foto (webcam / archivo) — portería.
 */
(function (global) {
    const STORAGE_ESCANER = 'smartcset_porteria_modo_escaner';
    const STORAGE_FOTO = 'smartcset_porteria_modo_foto';
    const FOTO_MAX_EDGE = 800;
    const FOTO_JPEG_QUALITY = 0.82;

    /**
     * @param {{
     *   form: HTMLFormElement,
     *   inputDoc: HTMLInputElement,
     *   resetEscaner?: boolean,
     * }} opts
     */
    function init(opts) {
        const form = opts.form;
        const inputDoc = opts.inputDoc;
        if (!form || !inputDoc) return;

        const btnEscaner = document.getElementById('btn_modo_escaner');
        const btnFoto = document.getElementById('btn_modo_foto');
        const hintEscaner = document.getElementById('pt_modo_escaner_hint');
        const panelFoto = document.getElementById('pt_foto_panel');
        const video = document.getElementById('pt_foto_video');
        const preview = document.getElementById('pt_foto_preview');
        const btnCapturar = document.getElementById('pt_foto_capturar');
        const btnArchivo = document.getElementById('pt_foto_archivo');
        const btnQuitar = document.getElementById('pt_foto_quitar');
        const inputFile = document.getElementById('pt_foto_file');
        const hidFoto = document.getElementById('hid_foto_data');
        const docWrap = inputDoc.closest('.ing-doc-row, .sal-doc-row');

        let modoEscaner = localStorage.getItem(STORAGE_ESCANER) === '1';
        let modoFoto = false;
        let stream = null;

        function setBtnActive(btn, on) {
            if (!btn) return;
            btn.classList.toggle('is-active', on);
            btn.setAttribute('aria-pressed', on ? 'true' : 'false');
        }

        function enfocarDocumento() {
            if (modoEscaner) {
                inputDoc.focus();
                inputDoc.select?.();
            }
        }

        function aplicarModoEscaner() {
            form.classList.toggle('is-modo-escaner', modoEscaner);
            if (docWrap) docWrap.classList.toggle('pt-doc-escaner-wrap', modoEscaner);
            hintEscaner?.classList.toggle('d-none', !modoEscaner);
            setBtnActive(btnEscaner, modoEscaner);
            localStorage.setItem(STORAGE_ESCANER, modoEscaner ? '1' : '0');
            if (modoEscaner) enfocarDocumento();
        }

        async function detenerCamara() {
            if (stream) {
                stream.getTracks().forEach((t) => t.stop());
                stream = null;
            }
            if (video) {
                video.srcObject = null;
                video.classList.remove('d-none');
            }
        }

        async function iniciarCamara() {
            if (!video || !global.navigator?.mediaDevices?.getUserMedia) {
                return false;
            }
            await detenerCamara();
            try {
                stream = await navigator.mediaDevices.getUserMedia({
                    video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
                    audio: false,
                });
                video.srcObject = stream;
                await video.play();
                return true;
            } catch {
                return false;
            }
        }

        function mostrarPreview(dataUrl) {
            if (!preview || !video) return;
            preview.src = dataUrl;
            preview.classList.remove('d-none');
            video.classList.add('d-none');
            btnQuitar?.classList.remove('d-none');
        }

        function quitarFoto() {
            if (hidFoto) hidFoto.value = '';
            preview?.classList.add('d-none');
            if (preview) preview.removeAttribute('src');
            video?.classList.remove('d-none');
            btnQuitar?.classList.add('d-none');
        }

        function comprimirImagen(fileOrBlob) {
            return new Promise((resolve, reject) => {
                const img = new Image();
                const url = URL.createObjectURL(fileOrBlob);
                img.onload = () => {
                    URL.revokeObjectURL(url);
                    const scale = Math.min(1, FOTO_MAX_EDGE / Math.max(img.width, img.height));
                    const w = Math.max(1, Math.round(img.width * scale));
                    const h = Math.max(1, Math.round(img.height * scale));
                    const canvas = document.createElement('canvas');
                    canvas.width = w;
                    canvas.height = h;
                    const ctx = canvas.getContext('2d');
                    if (!ctx) {
                        reject(new Error('canvas'));
                        return;
                    }
                    ctx.drawImage(img, 0, 0, w, h);
                    resolve(canvas.toDataURL('image/jpeg', FOTO_JPEG_QUALITY));
                };
                img.onerror = () => {
                    URL.revokeObjectURL(url);
                    reject(new Error('imagen'));
                };
                img.src = url;
            });
        }

        async function asignarFotoDesdeBlob(blob) {
            const dataUrl = await comprimirImagen(blob);
            if (hidFoto) hidFoto.value = dataUrl;
            mostrarPreview(dataUrl);
        }

        async function aplicarModoFoto() {
            panelFoto?.classList.toggle('d-none', !modoFoto);
            if (panelFoto) panelFoto.setAttribute('aria-hidden', modoFoto ? 'false' : 'true');
            setBtnActive(btnFoto, modoFoto);
            localStorage.setItem(STORAGE_FOTO, modoFoto ? '1' : '0');

            if (modoFoto) {
                if (modoEscaner) {
                    modoEscaner = false;
                    aplicarModoEscaner();
                }
                const ok = await iniciarCamara();
                if (!ok && btnArchivo) {
                    btnArchivo.focus();
                }
            } else {
                await detenerCamara();
                quitarFoto();
            }
        }

        btnEscaner?.addEventListener('click', () => {
            modoEscaner = !modoEscaner;
            if (modoEscaner && modoFoto) {
                modoFoto = false;
                aplicarModoFoto();
            }
            aplicarModoEscaner();
        });

        btnFoto?.addEventListener('click', () => {
            modoFoto = !modoFoto;
            aplicarModoFoto();
        });

        btnCapturar?.addEventListener('click', async () => {
            if (!video || video.classList.contains('d-none')) return;
            const canvas = document.createElement('canvas');
            canvas.width = video.videoWidth || 640;
            canvas.height = video.videoHeight || 480;
            const ctx = canvas.getContext('2d');
            if (!ctx) return;
            ctx.drawImage(video, 0, 0);
            canvas.toBlob(async (blob) => {
                if (blob) await asignarFotoDesdeBlob(blob);
            }, 'image/jpeg', FOTO_JPEG_QUALITY);
        });

        btnArchivo?.addEventListener('click', () => inputFile?.click());

        inputFile?.addEventListener('change', async () => {
            const file = inputFile.files?.[0];
            if (!file) return;
            await asignarFotoDesdeBlob(file);
            inputFile.value = '';
        });

        btnQuitar?.addEventListener('click', () => quitarFoto());

        inputDoc.addEventListener('blur', () => {
            if (!modoEscaner) return;
            global.setTimeout(() => {
                const active = document.activeElement;
                if (!active || !form.contains(active)) {
                    enfocarDocumento();
                    return;
                }
                if (active.closest?.('.pt-modos-toolbar, .pt-foto-panel, .ing-puerta, .sal-panel-foot')) {
                    return;
                }
                if (active === inputDoc) return;
                if (active.tagName === 'SELECT' || active.tagName === 'TEXTAREA' || active.tagName === 'BUTTON') {
                    return;
                }
                enfocarDocumento();
            }, 120);
        });

        function limpiarTrasRegistro() {
            inputDoc.value = '';
            if (global.PorteriaCaptura) {
                const hidCap = form.querySelector('#hid_captura_raw');
                const hidMet = form.querySelector('#hid_metodo_aut');
                const hidIng = form.querySelector('#hid_id_ingreso');
                if (hidCap) hidCap.value = '';
                if (hidMet) hidMet.value = String(global.PorteriaCaptura.METODO_MANUAL);
                if (hidIng) hidIng.value = '';
            }
            const bloque = form.querySelector('#bloque_ingreso');
            if (bloque) bloque.classList.add('d-none');
            const aviso = form.querySelector('#salida_aviso_msg');
            if (aviso) {
                aviso.classList.add('d-none');
                aviso.textContent = '';
            }
            quitarFoto();
            enfocarDocumento();
        }

        aplicarModoEscaner();
        if (localStorage.getItem(STORAGE_FOTO) === '1') {
            modoFoto = true;
            aplicarModoFoto();
        }

        if (opts.resetEscaner && modoEscaner) {
            limpiarTrasRegistro();
        }

        return { limpiarTrasRegistro, enfocarDocumento };
    }

    global.PorteriaMedios = { init, STORAGE_ESCANER };
})(typeof window !== 'undefined' ? window : globalThis);
