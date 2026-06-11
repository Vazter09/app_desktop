import { View, Text, StyleSheet } from 'react-native';
import { colors, spacing } from '../theme';

type Props = {
  online: boolean;
  pending: number;
};

export function OfflineBanner({ online, pending }: Props) {
  if (online && pending === 0) return null;

  return (
    <View style={[styles.banner, online ? styles.sync : styles.offline]}>
      <Text style={styles.text}>
        {!online
          ? 'Sin conexión — guardando localmente'
          : `${pending} registro(s) pendiente(s) de sincronizar`}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
  },
  offline: {
    backgroundColor: colors.warning,
  },
  sync: {
    backgroundColor: '#fff3cd',
  },
  text: {
    color: colors.text,
    fontWeight: '600',
    textAlign: 'center',
  },
});
