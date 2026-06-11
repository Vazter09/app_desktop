import * as SQLite from 'expo-sqlite';

const DB_NAME = 'smartcset_porteria.db';

let dbPromise: Promise<SQLite.SQLiteDatabase> | null = null;

export function getDb(): Promise<SQLite.SQLiteDatabase> {
  if (!dbPromise) {
    dbPromise = SQLite.openDatabaseAsync(DB_NAME).then(async (db) => {
      await db.execAsync(`
        PRAGMA journal_mode = WAL;
        CREATE TABLE IF NOT EXISTS pending_operations (
          client_id TEXT PRIMARY KEY NOT NULL,
          tipo TEXT NOT NULL CHECK (tipo IN ('ingreso', 'salida')),
          payload_json TEXT NOT NULL,
          foto_path TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          error TEXT,
          created_at TEXT NOT NULL,
          ingreso_client_id TEXT
        );
        CREATE TABLE IF NOT EXISTS catalogos_cache (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          json_data TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS local_accesos (
          tipo_doc TEXT NOT NULL,
          documento TEXT NOT NULL,
          ingreso_client_id TEXT NOT NULL,
          nombres TEXT,
          apellidos TEXT,
          id_entrada INTEGER,
          fec_local TEXT NOT NULL,
          cerrado INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (tipo_doc, documento)
        );
        CREATE INDEX IF NOT EXISTS idx_pending_status ON pending_operations(status, created_at);
      `);
      return db;
    });
  }
  return dbPromise;
}

export async function countPending(): Promise<number> {
  const db = await getDb();
  const row = await db.getFirstAsync<{ c: number }>(
    "SELECT COUNT(*) AS c FROM pending_operations WHERE status IN ('pending', 'failed')"
  );
  return row?.c ?? 0;
}

export async function saveCatalogosCache(json: string): Promise<void> {
  const db = await getDb();
  const now = new Date().toISOString();
  await db.runAsync(
    `INSERT INTO catalogos_cache (id, json_data, updated_at) VALUES (1, ?, ?)
     ON CONFLICT(id) DO UPDATE SET json_data = excluded.json_data, updated_at = excluded.updated_at`,
    json,
    now
  );
}

export async function loadCatalogosCache(): Promise<string | null> {
  const db = await getDb();
  const row = await db.getFirstAsync<{ json_data: string }>(
    'SELECT json_data FROM catalogos_cache WHERE id = 1'
  );
  return row?.json_data ?? null;
}

export async function enqueueOperation(
  clientId: string,
  tipo: 'ingreso' | 'salida',
  payloadJson: string,
  fotoPath: string | null,
  ingresoClientId: string | null = null
): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `INSERT INTO pending_operations (client_id, tipo, payload_json, foto_path, status, created_at, ingreso_client_id)
     VALUES (?, ?, ?, ?, 'pending', ?, ?)`,
    clientId,
    tipo,
    payloadJson,
    fotoPath,
    new Date().toISOString(),
    ingresoClientId
  );
}

export async function listPendingOps(limit = 20): Promise<
  {
    client_id: string;
    tipo: string;
    payload_json: string;
    foto_path: string | null;
    status: string;
    error: string | null;
    created_at: string;
    ingreso_client_id: string | null;
  }[]
> {
  const db = await getDb();
  return db.getAllAsync(
    `SELECT client_id, tipo, payload_json, foto_path, status, error, created_at, ingreso_client_id
       FROM pending_operations
      WHERE status IN ('pending', 'failed')
      ORDER BY created_at ASC
      LIMIT ?`,
    limit
  );
}

export async function listFailedOps(): Promise<
  {
    client_id: string;
    tipo: string;
    payload_json: string;
    error: string | null;
    created_at: string;
  }[]
> {
  const db = await getDb();
  return db.getAllAsync(
    `SELECT client_id, tipo, payload_json, error, created_at
       FROM pending_operations
      WHERE status = 'failed'
      ORDER BY created_at DESC`
  );
}

export async function markOperation(clientId: string, status: string, error: string | null = null): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    'UPDATE pending_operations SET status = ?, error = ? WHERE client_id = ?',
    status,
    error,
    clientId
  );
}

export async function resetFailedToPending(clientId: string): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    "UPDATE pending_operations SET status = 'pending', error = NULL WHERE client_id = ?",
    clientId
  );
}

export async function upsertLocalAcceso(
  tipoDoc: string,
  documento: string,
  ingresoClientId: string,
  nombres: string,
  apellidos: string,
  idEntrada: number
): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `INSERT INTO local_accesos (tipo_doc, documento, ingreso_client_id, nombres, apellidos, id_entrada, fec_local, cerrado)
     VALUES (?, ?, ?, ?, ?, ?, ?, 0)
     ON CONFLICT(tipo_doc, documento) DO UPDATE SET
       ingreso_client_id = excluded.ingreso_client_id,
       nombres = excluded.nombres,
       apellidos = excluded.apellidos,
       id_entrada = excluded.id_entrada,
       fec_local = excluded.fec_local,
       cerrado = 0`,
    tipoDoc,
    documento,
    ingresoClientId,
    nombres,
    apellidos,
    idEntrada,
    new Date().toISOString()
  );
}

export async function cerrarLocalAcceso(tipoDoc: string, documento: string): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    'UPDATE local_accesos SET cerrado = 1 WHERE tipo_doc = ? AND documento = ?',
    tipoDoc,
    documento
  );
}

export async function getLocalAccesoAbierto(
  tipoDoc: string,
  documento: string
): Promise<{
  ingreso_client_id: string;
  nombres: string;
  apellidos: string;
  id_entrada: number;
  fec_local: string;
} | null> {
  const db = await getDb();
  const row = await db.getFirstAsync<{
    ingreso_client_id: string;
    nombres: string;
    apellidos: string;
    id_entrada: number;
    fec_local: string;
  }>(
    'SELECT ingreso_client_id, nombres, apellidos, id_entrada, fec_local FROM local_accesos WHERE tipo_doc = ? AND documento = ? AND cerrado = 0',
    tipoDoc,
    documento
  );
  return row ?? null;
}
