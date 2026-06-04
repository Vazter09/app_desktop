/**
 * Captura de documento en portería: PDF417 (cédula CO), dígito manual, pistola.
 * Convención PDF417 (@): [0]=NUIP, [1]=apellido1, [2]=apellido2, [3]=nombre1, [4]=nombre2.
 *
 * Documentación línea por línea: docs/porteria-codigo-linea-a-linea.md
 * @see PorteriaCaptura.parseCapturaDocumento
 * @see PorteriaCaptura.enlazarCapturaDocumento
 */
(function (global) {
    const METODO_MANUAL = 1;
    const METODO_BARRAS = 3;
    const PDF417_MIN_LEN = 40;
    const SCAN_GAP_MS = 45;

    /**
     * @param {string} raw
     * @returns {{ documento: string, nombres: string, apellidos: string, origen: 'manual'|'pdf417', tipo_doc: string, captura_raw: string }}
     */
    function parseCapturaDocumento(raw) {
        const trimmed = String(raw || '').trim();
        if (!trimmed) {
            return emptyResult('');
        }

        if (trimmed.includes('@') && trimmed.length >= PDF417_MIN_LEN) {
            return parsePdf417Colombia(trimmed);
        }

        const documento = trimmed.replace(/\D/g, '').slice(0, 10);
        return {
            documento,
            nombres: '',
            apellidos: '',
            origen: 'manual',
            tipo_doc: 'CC',
            captura_raw: trimmed,
        };
    }

    function emptyResult(raw) {
        return {
            documento: '',
            nombres: '',
            apellidos: '',
            origen: 'manual',
            tipo_doc: 'CC',
            captura_raw: raw,
        };
    }

    /**
     * PDF417 cédula colombiana (delimitador @).
     */
    function parsePdf417Colombia(raw) {
        const parts = raw.split('@').map((p) => p.trim());
        let documento = '';

        for (const part of parts) {
            const digits = part.replace(/\D/g, '');
            if (digits.length >= 6 && digits.length <= 10) {
                documento = digits;
                break;
            }
        }
        if (!documento && parts[0]) {
            documento = parts[0].replace(/\D/g, '').slice(0, 10);
        }

        const apellidos = joinNameParts(parts[1], parts[2]);
        const nombres = joinNameParts(parts[3], parts[4]);

        return {
            documento,
            nombres,
            apellidos,
            origen: 'pdf417',
            tipo_doc: 'CC',
            captura_raw: raw,
        };
    }

    function joinNameParts(...segments) {
        return segments
            .map((s) => String(s || '').trim())
            .filter((s) => s.length > 0 && !/^\d+$/.test(s))
            .join(' ')
            .trim();
    }

    function metodoAutDesdeOrigen(origen) {
        return origen === 'pdf417' ? METODO_BARRAS : METODO_MANUAL;
    }

    /**
     * Enlaza captura por escaneo (Enter / ráfaga) en un input de documento.
     * @param {HTMLInputElement} input
     * @param {{ onCaptura: (parsed: ReturnType<typeof parseCapturaDocumento>, esEscaneo: boolean) => void }} opts
     */
    function enlazarCapturaDocumento(input, opts) {
        if (!input || !opts?.onCaptura) return;

        let lastKeyAt = 0;
        let keyCount = 0;

        input.addEventListener('keydown', (e) => {
            const now = Date.now();
            if (now - lastKeyAt > SCAN_GAP_MS) {
                keyCount = 0;
            }
            lastKeyAt = now;

            if (e.key === 'Enter') {
                const raw = input.value.trim();
                if (raw.includes('@') && raw.length >= PDF417_MIN_LEN) {
                    e.preventDefault();
                    const parsed = parseCapturaDocumento(raw);
                    opts.onCaptura(parsed, true);
                }
                return;
            }

            if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
                keyCount += 1;
            }
        });

        input.addEventListener('paste', (e) => {
            const text = (e.clipboardData || global.clipboardData)?.getData('text') || '';
            if (text.includes('@') && text.length >= PDF417_MIN_LEN) {
                e.preventDefault();
                setTimeout(() => {
                    input.value = text.trim();
                    opts.onCaptura(parseCapturaDocumento(text.trim()), true);
                }, 0);
            }
        });

        input.addEventListener('input', () => {
            const raw = input.value.trim();
            if (raw.includes('@') && raw.length >= PDF417_MIN_LEN) {
                opts.onCaptura(parseCapturaDocumento(raw), keyCount >= 8);
            }
        });
    }

    /** Hora local (APP) desde TIMESTAMP de BD interpretado como UTC. */
    function formatDbTime(timestamp) {
        const s = String(timestamp || '').trim();
        if (!s) {
            return '—';
        }
        const iso = s.includes('T') ? s : s.replace(' ', 'T');
        const utc = /[Zz]|[+-]\d{2}:?\d{2}$/.test(iso) ? iso : `${iso}Z`;
        const d = new Date(utc);
        if (Number.isNaN(d.getTime())) {
            return '—';
        }
        return d.toLocaleTimeString('es-CO', {
            hour: '2-digit',
            minute: '2-digit',
            timeZone: 'America/Bogota',
        });
    }

    global.PorteriaCaptura = {
        METODO_MANUAL,
        METODO_BARRAS,
        PDF417_MIN_LEN,
        parseCapturaDocumento,
        metodoAutDesdeOrigen,
        enlazarCapturaDocumento,
        formatDbTime,
    };
})(typeof window !== 'undefined' ? window : globalThis);
