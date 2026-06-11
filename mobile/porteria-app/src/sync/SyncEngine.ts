import * as FileSystem from 'expo-file-system/legacy';
import * as Crypto from 'expo-crypto';
import {
  checkHealth,
  fetchCatalogos,
  syncBatch,
} from '../api/client';
import {
  countPending,
  enqueueOperation,
  listPendingOps,
  markOperation,
  saveCatalogosCache,
  cerrarLocalAcceso,
  upsertLocalAcceso,
} from '../db/schema';
import type { IngresoPayload, SalidaPayload } from '../types';

let syncTimer: ReturnType<typeof setInterval> | null = null;
let syncing = false;

export type SyncListener = (online: boolean, pending: number) => void;
const listeners = new Set<SyncListener>();

export function subscribeSync(listener: SyncListener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

async function notify(): Promise<void> {
  const online = await checkHealth();
  const pending = await countPending();
  listeners.forEach((fn) => fn(online, pending));
}

export function startSyncEngine(): void {
  if (syncTimer) return;
  void refreshCatalogosIfOnline();
  void runSync();
  syncTimer = setInterval(() => {
    void runSync();
  }, 30000);
}

export function stopSyncEngine(): void {
  if (syncTimer) {
    clearInterval(syncTimer);
    syncTimer = null;
  }
}

export async function refreshCatalogosIfOnline(): Promise<void> {
  const online = await checkHealth();
  if (!online) return;
  const res = await fetchCatalogos();
  if (res.ok) {
    await saveCatalogosCache(JSON.stringify(res.data));
  }
  await notify();
}

async function readFotoBase64(fotoPath: string | null): Promise<string | undefined> {
  if (!fotoPath) return undefined;
  try {
    const info = await FileSystem.getInfoAsync(fotoPath);
    if (!info.exists) return undefined;
    const b64 = await FileSystem.readAsStringAsync(fotoPath, {
      encoding: FileSystem.EncodingType.Base64,
    });
    return `data:image/jpeg;base64,${b64}`;
  } catch {
    return undefined;
  }
}

export async function runSync(): Promise<number> {
  if (syncing) return 0;
  const online = await checkHealth();
  await notify();
  if (!online) return 0;

  syncing = true;
  let synced = 0;
  try {
    const ops = await listPendingOps(20);
    if (ops.length === 0) return 0;

    const operaciones = [];
    for (const op of ops) {
      await markOperation(op.client_id, 'syncing');
      const payload = JSON.parse(op.payload_json) as Record<string, unknown>;
      const foto = await readFotoBase64(op.foto_path);
      if (foto) payload.foto_base64 = foto;
      payload.client_id = op.client_id;
      operaciones.push({
        client_id: op.client_id,
        tipo: op.tipo,
        payload,
        fec_local: op.created_at,
      });
    }

    const res = await syncBatch(operaciones);
    if (!res.ok) {
      for (const op of ops) {
        await markOperation(op.client_id, 'pending', res.error);
      }
      return 0;
    }

    for (const r of res.data.resultados) {
      if (r.ok) {
        await markOperation(r.client_id, 'synced');
        synced += 1;
        const op = ops.find((o) => o.client_id === r.client_id);
        if (op?.tipo === 'salida') {
          const payload = JSON.parse(op.payload_json) as SalidaPayload;
          await cerrarLocalAcceso(payload.tipo_doc, payload.documento);
        }
        if (op?.foto_path) {
          try {
            await FileSystem.deleteAsync(op.foto_path, { idempotent: true });
          } catch {
            /* ignore */
          }
        }
      } else {
        await markOperation(r.client_id, 'failed', r.error ?? 'Error de sync');
      }
    }
  } finally {
    syncing = false;
    await notify();
  }
  return synced;
}

export async function newClientId(): Promise<string> {
  const bytes = await Crypto.getRandomBytesAsync(16);
  const hex = Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-a${hex.slice(17, 20)}-${hex.slice(20, 32)}`;
}

export async function queueIngreso(
  payload: IngresoPayload,
  fotoPath: string | null
): Promise<string> {
  const clientId = payload.client_id ?? (await newClientId());
  payload.client_id = clientId;
  await enqueueOperation(clientId, 'ingreso', JSON.stringify(payload), fotoPath);
  await upsertLocalAcceso(
    payload.tipo_doc,
    payload.documento,
    clientId,
    payload.nombres,
    payload.apellidos,
    payload.id_entrada
  );
  await notify();
  return clientId;
}

export async function queueSalida(
  payload: SalidaPayload,
  fotoPath: string | null,
  ingresoClientId: string | null
): Promise<string> {
  const clientId = payload.client_id ?? (await newClientId());
  payload.client_id = clientId;
  await enqueueOperation(clientId, 'salida', JSON.stringify(payload), fotoPath, ingresoClientId);
  await cerrarLocalAcceso(payload.tipo_doc, payload.documento);
  await notify();
  return clientId;
}

export async function saveFotoLocal(uri: string): Promise<string> {
  const dir = `${FileSystem.documentDirectory}porteria_fotos/`;
  await FileSystem.makeDirectoryAsync(dir, { intermediates: true });
  const dest = `${dir}${Date.now()}.jpg`;
  await FileSystem.copyAsync({ from: uri, to: dest });
  return dest;
}
