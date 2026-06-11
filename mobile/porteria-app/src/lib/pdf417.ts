const PDF417_MIN_LEN = 40;
export const METODO_MANUAL = 1;
export const METODO_BARRAS = 3;

export type CapturaResult = {
  documento: string;
  nombres: string;
  apellidos: string;
  origen: 'manual' | 'pdf417';
  tipo_doc: string;
  captura_raw: string;
  metodo_aut: number;
};

function emptyResult(raw: string): CapturaResult {
  return {
    documento: '',
    nombres: '',
    apellidos: '',
    origen: 'manual',
    tipo_doc: 'CC',
    captura_raw: raw,
    metodo_aut: METODO_MANUAL,
  };
}

function joinNameParts(...segments: string[]): string {
  return segments
    .map((s) => String(s || '').trim())
    .filter((s) => s.length > 0 && !/^\d+$/.test(s))
    .join(' ')
    .trim();
}

function parsePdf417Colombia(raw: string): CapturaResult {
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

  const apellidos = joinNameParts(parts[1] ?? '', parts[2] ?? '');
  const nombres = joinNameParts(parts[3] ?? '', parts[4] ?? '');

  return {
    documento,
    nombres: nombres.toUpperCase(),
    apellidos: apellidos.toUpperCase(),
    origen: 'pdf417',
    tipo_doc: 'CC',
    captura_raw: raw,
    metodo_aut: METODO_BARRAS,
  };
}

export function parseCapturaDocumento(raw: string): CapturaResult {
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
    metodo_aut: METODO_MANUAL,
  };
}

export function normalizeDocumento(raw: string): string {
  return String(raw || '').replace(/\D/g, '').slice(0, 10);
}
