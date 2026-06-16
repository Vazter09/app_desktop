import { useEffect, useState } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import { verifyStoredSession } from '../src/lib/session';

export default function IndexScreen() {
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    void (async () => {
      const status = await verifyStoredSession();
      router.replace(status === 'ready' ? '/(tabs)/ingreso' : '/setup');
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
