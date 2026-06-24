export const ROUTER_PREFIX = '/routers/porteria/v1';
/** @deprecated use ROUTER_PREFIX */
export const API_PREFIX = ROUTER_PREFIX;

export type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string };

export type Catalogos = {
  tipos_doc: { id: string; nombre: string }[];
  tipos_persona: { id: number; nombre: string }[];
  entradas: { id: number; nombre: string; id_centro: number; id_sede: number }[];
};

export type Persona = {
  id_persona: number;
  tipo_doc: string;
  documento: string;
  nombres: string;
  apellidos: string;
  tipo_persona: number;
  nom_tipo_persona: string;
};

export type IngresoAbierto = {
  id_ingreso: number;
  fec_ingreso: string;
  id_entrada: number;
  nom_entrada: string;
  tipo_persona: number;
  nom_tipo_persona: string;
  nombres: string;
  apellidos: string;
};

export type IngresoPayload = {
  client_id?: string;
  tipo_doc: string;
  documento: string;
  captura_raw?: string;
  tipo_persona: number;
  nombres: string;
  apellidos: string;
  id_entrada: number;
  observaciones?: string;
  metodo_aut?: number;
  foto_base64?: string;
};

export type SalidaPayload = {
  client_id?: string;
  tipo_doc: string;
  documento: string;
  captura_raw?: string;
  observaciones?: string;
  metodo_aut?: number;
  foto_base64?: string;
};

export type PendingStatus = 'pending' | 'syncing' | 'synced' | 'failed';

export type PendingOperation = {
  client_id: string;
  tipo: 'ingreso' | 'salida';
  payload_json: string;
  foto_path: string | null;
  status: PendingStatus;
  error: string | null;
  created_at: string;
  ingreso_client_id: string | null;
};
