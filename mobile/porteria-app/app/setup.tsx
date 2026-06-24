import { useEffect, useState } from 'react';
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
import { checkHealthDetailed, validateDevice } from '../src/routers/client';
import {
  clearCredentials,
  getServerUrl,
  setDeviceToken,
  setEntradaDefault,
  setServerUrl,
  setSetupComplete,
} from '../src/lib/storage';
import { colors, spacing } from '../src/theme';

export default function SetupScreen() {
  const [serverUrl, setUrl] = useState('http://10.5.213.103/smartcset');
  const [token, setToken] = useState('');
  const [loading, setLoading] = useState(false);
  const [testing, setTesting] = useState(false);

  useEffect(() => {
    void getServerUrl().then((saved) => {
      if (saved) setUrl(saved);
    });
  }, []);

  const normalizedUrl = () => serverUrl.trim().replace(/\/+$/, '');

  const probarConexion = async () => {
    const url = normalizedUrl();
    if (!url.startsWith('http')) {
      Alert.alert('URL inválida', 'Use http://IP/ruta del servidor SmartCSET.');
      return;
    }
    setTesting(true);
    try {
      const health = await checkHealthDetailed(url);
      if (health.ok) {
        Alert.alert('Conexión OK', `La API respondió correctamente.\n\n${health.url ?? url}`);
        return;
      }
      Alert.alert(
        'Sin conexión',
        [
          health.url ?? `${url}/src/api/porteria/v1/health.php`,
          health.error ? `\nDetalle: ${health.error}` : '',
          '\nSi Chrome sí abre esa URL, reinstale el APK más reciente (HTTP en Android).',
        ]
          .filter(Boolean)
          .join('')
      );
    } finally {
      setTesting(false);
    }
  };

  const guardar = async () => {
    const url = normalizedUrl();
    if (!url.startsWith('http')) {
      Alert.alert('URL inválida', 'Use http://IP/ruta del servidor SmartCSET.');
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
      const health = await checkHealthDetailed(url);
      if (!health.ok) {
        Alert.alert(
          'Sin conexión',
          [
            'No se pudo contactar la API de portería.',
            '',
            health.url ?? `${url}/src/api/porteria/v1/health.php`,
            health.error ? `\nDetalle: ${health.error}` : '',
            '',
            'Pruebe primero el botón "Probar conexión".',
          ]
            .filter(Boolean)
            .join('\n')
        );
        return;
      }

      const valid = await validateDevice(url, tokenNorm);
      if (!valid.ok) {
        Alert.alert('Token inválido', valid.error ?? 'No autorizado.');
        return;
      }

      await setServerUrl(url);
      await setDeviceToken(tokenNorm);
      await setSetupComplete(true);
      if (valid.data.id_entrada_default) {
        await setEntradaDefault(valid.data.id_entrada_default);
      }
      router.replace('/(tabs)/ingreso');
    } finally {
      setLoading(false);
    }
  };

  const borrarConfig = () => {
    Alert.alert('Borrar configuración', '¿Eliminar URL y token guardados en esta tablet?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Borrar',
        style: 'destructive',
        onPress: () => {
          void clearCredentials().then(() => {
            setToken('');
            Alert.alert('Listo', 'Configuración borrada. Vuelva a ingresar URL y código.');
          });
        },
      },
    ]);
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <Text style={styles.title}>Configurar tablet</Text>
      <Text style={styles.sub}>SmartCSET Portería — una sola vez</Text>

      <Text style={styles.label}>URL del servidor</Text>
      <Text style={styles.hint}>
        Raíz de SmartCSET (sin barra final). Ej. http://10.5.213.103/smartcset
      </Text>
      <TextInput
        style={styles.input}
        value={serverUrl}
        onChangeText={setUrl}
        autoCapitalize="none"
        autoCorrect={false}
        placeholder="http://10.5.213.103/smartcset"
      />

      <TouchableOpacity
        style={styles.btnSecondary}
        onPress={() => void probarConexion()}
        disabled={testing || loading}
      >
        <Text style={styles.btnSecondaryText}>
          {testing ? 'Probando…' : 'Probar conexión (sin token)'}
        </Text>
      </TouchableOpacity>

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

      <TouchableOpacity style={styles.linkBtn} onPress={borrarConfig}>
        <Text style={styles.linkText}>Borrar configuración guardada</Text>
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
  hint: { fontSize: 12, color: colors.muted, marginBottom: spacing.xs },
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
  btnSecondary: {
    borderWidth: 1,
    borderColor: colors.primary,
    padding: spacing.md,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  btnSecondaryText: { color: colors.primary, fontWeight: '700', fontSize: 15 },
  linkBtn: { marginTop: spacing.lg, alignItems: 'center' },
  linkText: { color: colors.muted, fontSize: 14, textDecorationLine: 'underline' },
});
