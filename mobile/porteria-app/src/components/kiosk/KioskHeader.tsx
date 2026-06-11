import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { kiosk, spacing } from '../../theme';

type Props = {
  title?: string;
  stepLabel: string;
  totalSteps: number;
  currentStep: number;
  onBack?: () => void;
  showBack?: boolean;
};

export function KioskHeader({
  title = 'Registro Ingreso',
  stepLabel,
  totalSteps,
  currentStep,
  onBack,
  showBack = false,
}: Props) {
  return (
    <View style={styles.wrap}>
      {showBack && onBack ? (
        <TouchableOpacity style={styles.backRow} onPress={onBack} activeOpacity={0.75}>
          <Ionicons name="chevron-back" size={22} color={kiosk.accent} />
          <Text style={styles.backText}>Volver</Text>
        </TouchableOpacity>
      ) : null}
      <View style={styles.topRow}>
        <View style={styles.brand}>
          <View style={styles.icon}>
            <Text style={styles.iconText}>SC</Text>
          </View>
          <View>
            <Text style={styles.title}>{title}</Text>
            <Text style={styles.sub}>{stepLabel}</Text>
          </View>
        </View>
        <View style={styles.dots}>
          {Array.from({ length: totalSteps }, (_, i) => {
            const n = i + 1;
            let dotStyle = styles.dotPending;
            if (n < currentStep) dotStyle = styles.dotDone;
            if (n === currentStep) dotStyle = styles.dotActive;
            return <View key={n} style={[styles.dot, dotStyle]} />;
          })}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    paddingHorizontal: kiosk.screenPadding,
    paddingTop: spacing.md,
    paddingBottom: spacing.sm,
  },
  backRow: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 2,
    marginBottom: spacing.sm,
    paddingVertical: spacing.xs,
    paddingRight: spacing.md,
  },
  backText: {
    fontSize: 16,
    fontWeight: '700',
    color: kiosk.accent,
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
  },
  brand: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    flex: 1,
  },
  icon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: kiosk.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconText: {
    fontSize: 12,
    fontWeight: '800',
    color: '#041210',
  },
  title: {
    fontSize: 14,
    fontWeight: '800',
    letterSpacing: 1.5,
    textTransform: 'uppercase',
    color: kiosk.keyText,
  },
  sub: {
    fontSize: 13,
    color: kiosk.muted,
    marginTop: 2,
  },
  dots: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  dotPending: { backgroundColor: kiosk.dotPending },
  dotActive: { backgroundColor: kiosk.dotActive, width: 24, height: 8 },
  dotDone: { backgroundColor: kiosk.dotDone },
});
