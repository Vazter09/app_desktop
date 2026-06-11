import * as SecureStore from 'expo-secure-store';

const KEY_SERVER = 'smartcset_server_url';
const KEY_TOKEN = 'smartcset_device_token';
const KEY_ENTRADA = 'smartcset_entrada_default';

export async function getServerUrl(): Promise<string | null> {
  return SecureStore.getItemAsync(KEY_SERVER);
}

export async function setServerUrl(url: string): Promise<void> {
  await SecureStore.setItemAsync(KEY_SERVER, url.replace(/\/+$/, ''));
}

export async function getDeviceToken(): Promise<string | null> {
  return SecureStore.getItemAsync(KEY_TOKEN);
}

export async function setDeviceToken(token: string): Promise<void> {
  await SecureStore.setItemAsync(KEY_TOKEN, token.trim());
}

export async function getEntradaDefault(): Promise<number | null> {
  const v = await SecureStore.getItemAsync(KEY_ENTRADA);
  return v ? parseInt(v, 10) : null;
}

export async function setEntradaDefault(id: number | null): Promise<void> {
  if (id === null) {
    await SecureStore.deleteItemAsync(KEY_ENTRADA);
    return;
  }
  await SecureStore.setItemAsync(KEY_ENTRADA, String(id));
}

export async function clearCredentials(): Promise<void> {
  await SecureStore.deleteItemAsync(KEY_SERVER);
  await SecureStore.deleteItemAsync(KEY_TOKEN);
  await SecureStore.deleteItemAsync(KEY_ENTRADA);
}

export async function isConfigured(): Promise<boolean> {
  const url = await getServerUrl();
  const token = await getDeviceToken();
  return Boolean(url && token);
}
