import { useEffect, useState } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import { checkHealthDetailed } from '../src/api/client';
import { clearCredentials, getServerUrl, isConfigured } from '../src/lib/storage';

export default function IndexScreen() {
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    void (async () => {
      const configured = await isConfigured();
      if (!configured) {
        router.replace('/setup');
        setChecking(false);
        return;
      }
      const url = await getServerUrl();
      const health = url ? await checkHealthDetailed(url) : { ok: false };
      if (!health.ok) {
        await clearCredentials();
        router.replace('/setup');
      } else {
        router.replace('/(tabs)/ingreso');
      }
      setChecking(false);
    })();
  }, []);

  if (!checking) return null;

  return (
    <View style={styles.center}>
      <ActivityIndicator size="large" color="#004d40" />
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
});
