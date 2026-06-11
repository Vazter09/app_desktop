import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { kiosk, spacing } from '../../theme';

type IoniconName = ComponentProps<typeof Ionicons>['name'];
type Mode = 'ingreso' | 'egreso';

type Puerta = { id: number; nombre: string };

type Props = {
  puertas: Puerta[];
  selected: number;
  onSelect: (id: number) => void;
  mode?: Mode;
};

const modeIcon: Record<Mode, IoniconName> = {
  ingreso: 'enter-outline',
  egreso: 'exit-outline',
};

export function PuertaKioskGrid({ puertas, selected, onSelect, mode = 'ingreso' }: Props) {
  if (puertas.length === 0) {
    return (
      <View style={styles.emptyWrap}>
        <View style={styles.emptyCard}>
          <Ionicons name="warning-outline" size={36} color={kiosk.warning} />
          <Text style={styles.emptyTitle}>Sin puertas configuradas</Text>
          <Text style={styles.emptyMsg}>Contacte al administrador del sistema.</Text>
        </View>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.scroll}
      contentContainerStyle={styles.grid}
      showsVerticalScrollIndicator={false}
      keyboardShouldPersistTaps="handled"
    >
      {puertas.map((p) => {
        const active = selected === p.id;
        return (
          <TouchableOpacity
            key={p.id}
            style={[styles.card, active && styles.cardActive]}
            onPress={() => onSelect(p.id)}
            activeOpacity={0.75}
          >
            {active && (
              <View style={styles.check}>
                <Ionicons name="checkmark" size={14} color="#041210" />
              </View>
            )}
            <View style={[styles.numBadge, active && styles.numBadgeActive]}>
              <Text style={[styles.num, active && styles.numActive]}>{p.id}</Text>
            </View>
            <View style={styles.iconRow}>
              <Ionicons
                name={modeIcon[mode]}
                size={18}
                color={active ? kiosk.accent : kiosk.muted}
              />
            </View>
            <Text style={[styles.nom, active && styles.nomActive]} numberOfLines={2}>
              {p.nombre}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: {
    flex: 1,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignContent: 'flex-start',
    gap: spacing.md,
    paddingHorizontal: kiosk.screenPadding,
    paddingBottom: spacing.md,
  },
  card: {
    width: '47%',
    flexGrow: 1,
    minHeight: 136,
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing.md,
    borderRadius: 18,
    borderWidth: 1.5,
    borderColor: kiosk.keyBorder,
    backgroundColor: kiosk.keyBg,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  cardActive: {
    borderColor: kiosk.accent,
    backgroundColor: 'rgba(0, 229, 176, 0.14)',
    shadowColor: kiosk.accent,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.35,
    shadowRadius: 12,
    elevation: 4,
  },
  check: {
    position: 'absolute',
    top: spacing.sm,
    right: spacing.sm,
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: kiosk.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  numBadge: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: 'rgba(0, 229, 176, 0.12)',
    borderWidth: 1,
    borderColor: kiosk.panelBorder,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.xs,
  },
  numBadgeActive: {
    backgroundColor: kiosk.accent,
    borderColor: kiosk.accent,
  },
  num: {
    fontSize: 22,
    fontWeight: '800',
    color: kiosk.accent,
    fontVariant: ['tabular-nums'],
  },
  numActive: {
    color: '#041210',
  },
  iconRow: {
    marginBottom: spacing.xs,
  },
  nom: {
    fontSize: 13,
    fontWeight: '600',
    color: kiosk.muted,
    textAlign: 'center',
    lineHeight: 18,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  nomActive: {
    color: kiosk.keyText,
  },
  emptyWrap: {
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: kiosk.screenPadding,
  },
  emptyCard: {
    borderRadius: 18,
    borderWidth: 1.5,
    borderColor: kiosk.warningBorder,
    backgroundColor: kiosk.warningBg,
    padding: spacing.xl,
    alignItems: 'center',
    gap: spacing.sm,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: kiosk.keyText,
    textAlign: 'center',
  },
  emptyMsg: {
    fontSize: 14,
    color: kiosk.muted,
    textAlign: 'center',
  },
});
