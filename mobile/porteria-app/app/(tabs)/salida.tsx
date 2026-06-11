import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { OfflineBanner } from '../../src/components/OfflineBanner';
import { SalidaKioskFlow } from '../../src/components/kiosk/SalidaKioskFlow';
import { useCatalogos } from '../../src/hooks/useCatalogos';
import { useNetworkStatus } from '../../src/hooks/useNetworkStatus';
import { kiosk } from '../../src/theme';

export default function SalidaScreen() {
  const { catalogos, loading: loadingCat } = useCatalogos();
  const { online, pending } = useNetworkStatus();

  if (loadingCat && !catalogos) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={kiosk.accent} />
      </View>
    );
  }

  if (!catalogos) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={kiosk.accent} />
      </View>
    );
  }

  return (
    <View style={styles.flex}>
      <OfflineBanner online={online} pending={pending} />
      <SalidaKioskFlow catalogos={catalogos} online={online} />
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: kiosk.screenBg },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: kiosk.screenBg,
  },
});
