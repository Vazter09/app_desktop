import type { ApiResult, Catalogos } from '../types';
import { API_PREFIX } from '../types';
import { getDeviceToken, getServerUrl } from '../lib/storage';

async function buildHeaders(): Promise<HeadersInit> {
  const token = await getDeviceToken();
  const headers: Record<string, string> = {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

export async function apiUrl(path: string): Promise<string | null> {
  const base = await getServerUrl();
  if (!base) return null;
  const clean = path.startsWith('/') ? path : `/${path}`;
  return `${base}${API_PREFIX}${clean}`;
}

async function parseResponse<T>(res: Response): Promise<ApiResult<T>> {
  let body: { ok?: boolean; data?: T; error?: string } = {};
  try {
    body = await res.json();
  } catch {
    return { ok: false, error: 'Respuesta inválida del servidor.' };
  }
  if (!res.ok || body.ok === false) {
    return { ok: false, error: body.error ?? `Error HTTP ${res.status}` };
  }
  return { ok: true, data: body.data as T };
}

export async function checkHealth(): Promise<boolean> {
  const url = await apiUrl('/health.php');
  if (!url) return false;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 5000);
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);
    if (!res.ok) return false;
    const json = await res.json();
    return json.ok === true;
  } catch {
    return false;
  }
}

export async function validateDevice(): Promise<
  ApiResult<{
    id_dispositivo: number;
    nom_dispositivo: string;
    id_entrada_default: number | null;
  }>
> {
  const url = await apiUrl('/device/validate.php');
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, { method: 'POST', headers: await buildHeaders() });
  return parseResponse(res);
}

export async function fetchCatalogos(): Promise<ApiResult<Catalogos>> {
  const url = await apiUrl('/catalogos.php');
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, { headers: await buildHeaders() });
  return parseResponse(res);
}

export async function consultarIngreso(
  documento: string,
  tipoDoc: string
): Promise<
  ApiResult<{
    persona: unknown;
    ingreso_abierto: unknown;
    puede_ingresar: boolean;
  }>
> {
  const url = await apiUrl(
    `/ingreso/consultar.php?documento=${encodeURIComponent(documento)}&tipo_doc=${encodeURIComponent(tipoDoc)}`
  );
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, { headers: await buildHeaders() });
  return parseResponse(res);
}

export async function registrarIngreso(payload: Record<string, unknown>): Promise<
  ApiResult<{ id_ingreso: number }>
> {
  const url = await apiUrl('/ingreso/registrar.php');
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, {
    method: 'POST',
    headers: await buildHeaders(),
    body: JSON.stringify(payload),
  });
  return parseResponse(res);
}

export async function listIngresosHoy(): Promise<
  ApiResult<{ items: Record<string, unknown>[] }>
> {
  const url = await apiUrl('/ingreso/hoy.php');
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, { headers: await buildHeaders() });
  return parseResponse(res);
}

export async function consultarSalida(
  documento: string,
  tipoDoc: string
): Promise<
  ApiResult<{
    persona: unknown;
    ingreso_abierto: unknown;
    puede_salir: boolean;
  }>
> {
  const url = await apiUrl(
    `/salida/consultar.php?documento=${encodeURIComponent(documento)}&tipo_doc=${encodeURIComponent(tipoDoc)}`
  );
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, { headers: await buildHeaders() });
  return parseResponse(res);
}

export async function registrarSalida(payload: Record<string, unknown>): Promise<
  ApiResult<{ id_ingreso: number }>
> {
  const url = await apiUrl('/salida/registrar.php');
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, {
    method: 'POST',
    headers: await buildHeaders(),
    body: JSON.stringify(payload),
  });
  return parseResponse(res);
}

export async function listSalidasHoy(): Promise<
  ApiResult<{ items: Record<string, unknown>[] }>
> {
  const url = await apiUrl('/salida/hoy.php');
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, { headers: await buildHeaders() });
  return parseResponse(res);
}

export async function syncBatch(operaciones: Record<string, unknown>[]): Promise<
  ApiResult<{ resultados: { client_id: string; ok: boolean; id_ingreso?: number; error?: string }[] }>
> {
  const url = await apiUrl('/sync/batch.php');
  if (!url) return { ok: false, error: 'Servidor no configurado.' };
  const res = await fetch(url, {
    method: 'POST',
    headers: await buildHeaders(),
    body: JSON.stringify({ operaciones }),
  });
  return parseResponse(res);
}
