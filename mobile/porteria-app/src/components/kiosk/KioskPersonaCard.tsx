import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { kiosk, spacing } from '../../theme';

type Props = {
  nombre: string;
  tipo: string;
  documento: string;
  meta?: string;
};

export function KioskPersonaCard({ nombre, tipo, documento, meta }: Props) {
  return (
    <View style={styles.card}>
      <View style={styles.avatar}>
        <Ionicons name="person" size={28} color={kiosk.accent} />
      </View>
      <Text style={styles.nombre}>{nombre}</Text>
      <View style={styles.badge}>
        <Text style={styles.tipo}>{tipo}</Text>
      </View>
      <View style={styles.docRow}>
        <Ionicons name="card-outline" size={16} color={kiosk.label} />
        <Text style={styles.doc}>CC {documento}</Text>
      </View>
      {meta ? <Text style={styles.meta}>{meta}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: kiosk.screenPadding,
    marginBottom: spacing.lg,
    padding: spacing.xl,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: kiosk.panelBorder,
    backgroundColor: kiosk.displayBg,
    alignItems: 'center',
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: kiosk.infoBg,
    borderWidth: 1.5,
    borderColor: kiosk.panelBorder,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
  },
  nombre: {
    fontSize: 24,
    fontWeight: '800',
    color: kiosk.keyText,
    textAlign: 'center',
    marginBottom: spacing.sm,
  },
  badge: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.xs,
    borderRadius: 20,
    backgroundColor: 'rgba(0, 229, 176, 0.12)',
    borderWidth: 1,
    borderColor: kiosk.panelBorder,
    marginBottom: spacing.md,
  },
  tipo: {
    fontSize: 13,
    fontWeight: '700',
    color: kiosk.accent,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
  },
  docRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  doc: {
    fontSize: 15,
    color: kiosk.muted,
    fontVariant: ['tabular-nums'],
  },
  meta: {
    fontSize: 13,
    color: kiosk.label,
    marginTop: spacing.md,
    textAlign: 'center',
  },
});
