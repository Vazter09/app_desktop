import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { router } from 'expo-router';
import { checkHealth, validateDevice } from '../src/api/client';
import {
  setDeviceToken,
  setEntradaDefault,
  setServerUrl,
} from '../src/lib/storage';
import { colors, spacing } from '../src/theme';

export default function SetupScreen() {
  const [serverUrl, setUrl] = useState('http://192.168.1.50:8080');
  const [token, setToken] = useState('');
  const [loading, setLoading] = useState(false);

  const guardar = async () => {
    const url = serverUrl.trim().replace(/\/+$/, '');
    if (!url.startsWith('http')) {
      Alert.alert('URL inválida', 'Use http://IP:puerto del servidor SmartCSET.');
      return;
    }
    const tokenNorm = token.trim().toUpperCase();
    if (!/^[A-Z0-9]{6}$/.test(tokenNorm)) {
      Alert.alert(
        'Token inválido',
        'Use el código de 6 caracteres alfanuméricos generado en el servidor.'
      );
      return;
    }
    setLoading(true);
    try {
      await setServerUrl(url);
      await setDeviceToken(tokenNorm);
      const health = await checkHealth();
      if (!health) {
        Alert.alert('Sin conexión', 'No se pudo contactar el servidor en esa URL.');
        return;
      }
      const valid = await validateDevice();
      if (!valid.ok) {
        Alert.alert('Token inválido', valid.error);
        return;
      }
      if (valid.data.id_entrada_default) {
        await setEntradaDefault(valid.data.id_entrada_default);
      }
      router.replace('/(tabs)/ingreso');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <Text style={styles.title}>Configurar tablet</Text>
      <Text style={styles.sub}>SmartCSET Portería — una sola vez</Text>

      <Text style={styles.label}>URL del servidor</Text>
      <TextInput
        style={styles.input}
        value={serverUrl}
        onChangeText={setUrl}
        autoCapitalize="none"
        autoCorrect={false}
        placeholder="http://192.168.1.50:8080"
      />

      <Text style={styles.label}>Token del dispositivo</Text>
      <TextInput
        style={styles.input}
        value={token}
        onChangeText={(v) => setToken(v.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6))}
        autoCapitalize="characters"
        autoCorrect={false}
        maxLength={6}
        placeholder="ABC123"
      />

      <TouchableOpacity style={styles.btn} onPress={() => void guardar()} disabled={loading}>
        <Text style={styles.btnText}>{loading ? 'Validando…' : 'Guardar y continuar'}</Text>
      </TouchableOpacity>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: spacing.lg,
    justifyContent: 'center',
    backgroundColor: colors.bg,
  },
  title: { fontSize: 28, fontWeight: '700', color: colors.primary },
  sub: { color: colors.muted, marginBottom: spacing.lg },
  label: { fontWeight: '600', marginBottom: spacing.xs, color: colors.text },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    marginBottom: spacing.md,
    backgroundColor: colors.card,
    fontSize: 16,
  },
  btn: {
    backgroundColor: colors.primary,
    padding: spacing.md,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: spacing.md,
  },
  btnText: { color: '#fff', fontWeight: '700', fontSize: 16 },
});
