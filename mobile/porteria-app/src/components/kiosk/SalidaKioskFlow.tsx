import { useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useSalidaKiosk } from '../../hooks/useSalidaKiosk';
import type { Catalogos } from '../../types';
import { kiosk as kioskTheme, spacing } from '../../theme';
import { KioskHeader } from './KioskHeader';
import { DocumentDisplay } from './DocumentDisplay';
import { NumericKeypad } from './NumericKeypad';
import { PuertaKioskStep } from './PuertaKioskStep';
import { KioskStatusPanel } from './KioskStatusPanel';
import { KioskPersonaCard } from './KioskPersonaCard';

type Props = {
  catalogos: Catalogos;
  online: boolean;
};

function stepProgress(step: string): { current: number; total: number; label: string } {
  switch (step) {
    case 'documento':
      return { current: 1, total: 3, label: 'Paso 1 de 3' };
    case 'confirmacion':
      return { current: 2, total: 3, label: 'Paso 2 de 3' };
    case 'puerta':
      return { current: 3, total: 3, label: 'Paso 3 de 3' };
    default:
      return { current: 1, total: 3, label: 'Paso 1 de 3' };
  }
}

export function SalidaKioskFlow({ catalogos, online }: Props) {
  const scanRef = useRef<TextInput>(null);
  const insets = useSafeAreaInsets();
  const state = useSalidaKiosk({ catalogos, online });

  const progress = stepProgress(state.step);
  const primerNombre = state.displayNombre.split(' ')[0] ?? '';

  const renderAccentBtn = (
    label: string,
    onPress: () => void,
    disabled?: boolean,
    inRow?: boolean,
    solid?: boolean
  ) => (
    <TouchableOpacity
      style={[
        solid ? styles.accentBtnSolid : styles.accentBtn,
        inRow && styles.accentBtnInRow,
        disabled && styles.accentBtnDisabled,
      ]}
      onPress={onPress}
      disabled={disabled}
      activeOpacity={0.8}
    >
      <Text
        style={[
          solid ? styles.accentBtnTextSolid : styles.accentBtnText,
          disabled && styles.accentBtnTextDisabled,
        ]}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );

  const renderGhostBtn = (label: string, onPress: () => void, inRow?: boolean) => (
    <TouchableOpacity
      style={[styles.ghostBtn, inRow && styles.ghostBtnInRow]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      <Text style={styles.ghostBtnText}>{label}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={[styles.panel, { paddingTop: insets.top }]}>
      <KioskHeader
        title="Registro Egreso"
        stepLabel={progress.label}
        totalSteps={progress.total}
        currentStep={progress.current}
        showBack={state.canGoBack && state.step !== 'puerta'}
        onBack={state.goBack}
      />

      {state.step === 'documento' && (
        <View style={styles.stepFill}>
          <Text style={styles.sectionLabelHero}>Ingrese su documento</Text>
          <DocumentDisplay documento={state.documento} />
          <View style={styles.keypadFill}>
            <NumericKeypad
              onDigit={state.appendDigit}
              onDelete={state.deleteDigit}
              fill
            />
          </View>
          <View style={styles.footer}>
            {renderAccentBtn(
              'Continuar →',
              () => void state.continueFromDocumento(),
              !state.canContinueDocumento
            )}
          </View>
          <TextInput
            ref={scanRef}
            style={styles.hiddenInput}
            autoFocus
            onSubmitEditing={(e) => void state.applyScan(e.nativeEvent.text)}
            blurOnSubmit={false}
            onChangeText={(t) => {
              if (t.includes('@') && t.length >= 40) {
                void state.applyScan(t);
              }
            }}
          />
        </View>
      )}

      {state.step === 'confirmacion' && (
        <View style={styles.stepFill}>
          {state.consultLoading ? (
            <KioskStatusPanel
              variant="info"
              icon="search-outline"
              title="Consultando"
              message=""
              loading
              loadingText="Buscando ingreso activo…"
              actions={[]}
            />
          ) : state.puedeSalir ? (
            <View style={styles.confirmFill}>
              <KioskPersonaCard
                nombre={state.displayNombre}
                tipo={state.displayTipo}
                documento={state.documento}
                meta={
                  state.ingresoAbierto && state.ingresoAbierto.id_ingreso > 0
                    ? `Ingreso #${state.ingresoAbierto.id_ingreso}${
                        state.ingresoAbierto.nom_entrada
                          ? ` — ${state.ingresoAbierto.nom_entrada}`
                          : ''
                      }`
                    : undefined
                }
              />
              <Text style={styles.confirmQuestion}>
                ¿Confirma que usted es {primerNombre}?
              </Text>
              <View style={styles.footerRow}>
                {renderGhostBtn('Corregir', state.correct, true)}
                {renderAccentBtn('Sí, soy yo', state.confirmIdentity, false, true, true)}
              </View>
            </View>
          ) : (
            <KioskStatusPanel
              variant="neutral"
              icon="log-out-outline"
              title="Sin ingreso activo"
              message="No encontramos un ingreso abierto para este documento. Verifique el número o registre primero el ingreso."
              actions={[{ label: 'Corregir documento', onPress: state.correct, primary: true }]}
            />
          )}
        </View>
      )}

      {state.step === 'puerta' && (
        <PuertaKioskStep
          mode="egreso"
          puertas={state.puertas}
          selected={state.idEntrada}
          onSelect={state.selectPuerta}
          busy={state.busy}
          canConfirm={state.canConfirmPuerta}
          onConfirm={() => void state.confirmRegister()}
          onBack={state.canGoBack ? state.goBack : undefined}
        />
      )}
    </View>
  );
}

const accent = kioskTheme.accent;

const styles = StyleSheet.create({
  panel: {
    flex: 1,
    backgroundColor: kioskTheme.panelBg,
  },
  stepFill: {
    flex: 1,
    minHeight: 0,
  },
  keypadFill: {
    flex: 1,
    minHeight: 0,
  },
  confirmFill: {
    flex: 1,
    justifyContent: 'center',
    paddingBottom: spacing.xl,
  },
  sectionLabelHero: {
    fontSize: kioskTheme.sectionFontSize,
    fontWeight: '800',
    letterSpacing: 0.5,
    color: kioskTheme.accent,
    textAlign: 'center',
    marginBottom: spacing.md,
    paddingHorizontal: kioskTheme.screenPadding,
  },
  sectionLabel: {
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.5,
    color: kioskTheme.label,
    textAlign: 'center',
    marginBottom: spacing.md,
    paddingHorizontal: kioskTheme.screenPadding,
  },
  footer: {
    paddingHorizontal: kioskTheme.screenPadding,
    paddingBottom: spacing.md,
    paddingTop: spacing.sm,
  },
  accentBtn: {
    paddingVertical: 18,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: accent,
    backgroundColor: 'rgba(0, 229, 176, 0.12)',
    alignItems: 'center',
  },
  accentBtnSolid: {
    paddingVertical: 18,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: accent,
    backgroundColor: accent,
    alignItems: 'center',
  },
  accentBtnInRow: {
    flex: 1,
    marginHorizontal: 0,
    marginTop: 0,
  },
  accentBtnDisabled: {
    opacity: 0.28,
    borderColor: kioskTheme.keyBorder,
  },
  accentBtnText: {
    color: accent,
    fontWeight: '800',
    fontSize: 17,
    letterSpacing: 0.5,
  },
  accentBtnTextSolid: {
    color: '#041210',
    fontWeight: '800',
    fontSize: 17,
    letterSpacing: 0.5,
  },
  accentBtnTextDisabled: {
    color: kioskTheme.muted,
  },
  footerRow: {
    flexDirection: 'row',
    paddingHorizontal: kioskTheme.screenPadding,
    gap: spacing.md,
    marginTop: spacing.lg,
  },
  ghostBtn: {
    paddingVertical: 18,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: kioskTheme.keyBorder,
    backgroundColor: kioskTheme.keyBg,
    alignItems: 'center',
    marginHorizontal: kioskTheme.screenPadding,
    marginTop: spacing.sm,
  },
  ghostBtnInRow: {
    flex: 1,
    marginHorizontal: 0,
    marginTop: 0,
  },
  ghostBtnText: {
    color: kioskTheme.muted,
    fontWeight: '700',
    fontSize: 16,
  },
  confirmQuestion: {
    fontSize: 18,
    color: kioskTheme.keyText,
    textAlign: 'center',
    paddingHorizontal: kioskTheme.screenPadding,
    marginBottom: spacing.md,
  },
  hiddenInput: {
    position: 'absolute',
    width: 1,
    height: 1,
    opacity: 0,
  },
});
