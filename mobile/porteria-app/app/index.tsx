import { useEffect, useState } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import { isConfigured } from '../src/lib/storage';

export default function IndexScreen() {
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    void (async () => {
      const ok = await isConfigured();
      router.replace(ok ? '/(tabs)/ingreso' : '/setup');
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
