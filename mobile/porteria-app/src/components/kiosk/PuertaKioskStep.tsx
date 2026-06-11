import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { kiosk, spacing } from '../../theme';
import { PuertaKioskGrid } from './PuertaKioskGrid';
import type { PuertaItem } from '../../lib/puertaLabels';

type Mode = 'ingreso' | 'egreso';

type Props = {
  mode: Mode;
  puertas: PuertaItem[];
  selected: number;
  onSelect: (id: number) => void;
  busy: boolean;
  canConfirm: boolean;
  onConfirm: () => void;
  onBack?: () => void;
};

const copy: Record<Mode, { hero: string; hint: string; confirm: string; confirmBusy: string }> = {
  ingreso: {
    hero: 'Seleccione la puerta de ingreso',
    hint: 'Toque una puerta para continuar',
    confirm: 'Confirmar ingreso',
    confirmBusy: 'Registrando…',
  },
  egreso: {
    hero: 'Seleccione la puerta de egreso',
    hint: 'Toque una puerta para continuar',
    confirm: 'Confirmar egreso',
    confirmBusy: 'Registrando…',
  },
};

export function PuertaKioskStep({
  mode,
  puertas,
  selected,
  onSelect,
  busy,
  canConfirm,
  onConfirm,
  onBack,
}: Props) {
  const t = copy[mode];
  const selectedPuerta = puertas.find((p) => p.id === selected);

  return (
    <View style={styles.wrap}>
      <Text style={styles.hero}>{t.hero}</Text>
      {!canConfirm && puertas.length > 0 ? (
        <Text style={styles.hint}>{t.hint}</Text>
      ) : selectedPuerta ? (
        <Text style={styles.selectedHint}>Puerta: {selectedPuerta.nombre}</Text>
      ) : null}

      <PuertaKioskGrid
        mode={mode}
        puertas={puertas}
        selected={selected}
        onSelect={onSelect}
      />

      <View style={styles.footer}>
        <View style={styles.footerRow}>
          {onBack ? (
            <TouchableOpacity
              style={[styles.backBtn, busy && styles.backBtnDisabled]}
              onPress={onBack}
              disabled={busy}
              activeOpacity={0.8}
            >
              <Text style={styles.backBtnText}>← Volver</Text>
            </TouchableOpacity>
          ) : null}
          <TouchableOpacity
            style={[
              styles.confirmBtn,
              onBack && styles.confirmBtnRow,
              canConfirm ? styles.confirmBtnReady : styles.confirmBtnDisabled,
            ]}
            onPress={onConfirm}
            disabled={!canConfirm}
            activeOpacity={0.85}
          >
            <Text
              style={[
                styles.confirmText,
                canConfirm ? styles.confirmTextReady : styles.confirmTextDisabled,
              ]}
            >
              {busy ? t.confirmBusy : t.confirm}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    minHeight: 0,
  },
  hero: {
    fontSize: kiosk.sectionFontSize,
    fontWeight: '800',
    letterSpacing: 0.5,
    color: kiosk.accent,
    textAlign: 'center',
    marginBottom: spacing.xs,
    paddingHorizontal: kiosk.screenPadding,
  },
  hint: {
    fontSize: 14,
    color: kiosk.muted,
    textAlign: 'center',
    marginBottom: spacing.md,
    paddingHorizontal: kiosk.screenPadding,
  },
  selectedHint: {
    fontSize: 14,
    fontWeight: '600',
    color: kiosk.keyText,
    textAlign: 'center',
    marginBottom: spacing.md,
    paddingHorizontal: kiosk.screenPadding,
    opacity: 0.85,
  },
  footer: {
    paddingHorizontal: kiosk.screenPadding,
    paddingBottom: spacing.md,
    paddingTop: spacing.sm,
  },
  footerRow: {
    flexDirection: 'row',
    gap: spacing.md,
    alignItems: 'stretch',
  },
  backBtn: {
    flex: 1,
    paddingVertical: 18,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: kiosk.keyBorder,
    backgroundColor: kiosk.keyBg,
  },
  backBtnDisabled: {
    opacity: 0.5,
  },
  backBtnText: {
    fontWeight: '700',
    fontSize: 16,
    color: kiosk.keyText,
  },
  confirmBtn: {
    paddingVertical: 18,
    borderRadius: 14,
    alignItems: 'center',
    borderWidth: 1.5,
  },
  confirmBtnRow: {
    flex: 1.4,
  },
  confirmBtnReady: {
    backgroundColor: kiosk.accent,
    borderColor: kiosk.accent,
  },
  confirmBtnDisabled: {
    backgroundColor: kiosk.keyBg,
    borderColor: kiosk.keyBorder,
    opacity: 0.55,
  },
  confirmText: {
    fontWeight: '800',
    fontSize: 17,
    letterSpacing: 0.5,
  },
  confirmTextReady: {
    color: '#041210',
  },
  confirmTextDisabled: {
    color: kiosk.muted,
  },
});
