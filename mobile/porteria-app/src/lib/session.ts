import { checkHealthDetailed, validateDevice } from '../api/client';
import {
  clearCredentials,
  getDeviceToken,
  getServerUrl,
  isSetupComplete,
  setEntradaDefault,
} from './storage';

export type SessionStatus = 'setup' | 'ready';

/**
 * Comprueba URL + token guardados contra el servidor.
 * Si falta algo o el token ya no es válido, borra credenciales y pide setup.
 */
export async function verifyStoredSession(): Promise<SessionStatus> {
  const url = await getServerUrl();
  const token = await getDeviceToken();
  const complete = await isSetupComplete();

  if (!url || !token || !complete) {
    return 'setup';
  }

  const health = await checkHealthDetailed(url);
  if (!health.ok) {
    await clearCredentials();
    return 'setup';
  }

  const valid = await validateDevice(url, token);
  if (!valid.ok) {
    await clearCredentials();
    return 'setup';
  }

  if (valid.data.id_entrada_default) {
    await setEntradaDefault(valid.data.id_entrada_default);
  }

  return 'ready';
}
