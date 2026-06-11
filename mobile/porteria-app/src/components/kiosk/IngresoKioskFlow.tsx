import { useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useIngresoKiosk } from '../../hooks/useIngresoKiosk';
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

function stepProgress(
  step: string,
  flow: 'known' | 'new' | null
): { current: number; total: number; label: string } {
  const isNew = flow === 'new';
  switch (step) {
    case 'documento':
      return { current: 1, total: 3, label: 'Paso 1 de 3' };
    case 'confirmacion':
      return {
        current: 2,
        total: isNew ? 4 : 3,
        label: `Paso 2 de ${isNew ? 4 : 3}`,
      };
    case 'datos':
      return { current: 3, total: 4, label: 'Paso 3 de 4' };
    case 'puerta':
      return {
        current: isNew ? 4 : 3,
        total: isNew ? 4 : 3,
        label: `Paso ${isNew ? 4 : 3} de ${isNew ? 4 : 3}`,
      };
    default:
      return { current: 1, total: 3, label: 'Paso 1 de 3' };
  }
}

export function IngresoKioskFlow({ catalogos, online }: Props) {
  const scanRef = useRef<TextInput>(null);
  const insets = useSafeAreaInsets();
  const state = useIngresoKiosk({ catalogos, online });

  const progress = stepProgress(state.step, state.flow);
  const primerNombre = state.persona?.nombres?.split(' ')[0] ?? '';
  const nombreCompleto = state.persona
    ? `${state.persona.nombres} ${state.persona.apellidos}`.trim()
    : '';

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
        title="Registro Ingreso"
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
              loadingText="Buscando persona…"
              actions={[]}
            />
          ) : !state.puedeIngresar ? (
            <KioskStatusPanel
              variant="warning"
              icon="alert-circle-outline"
              title="Ingreso no permitido"
              message="Ya tiene un ingreso activo hoy. Registre primero el egreso para volver a ingresar."
              actions={[{ label: 'Corregir documento', onPress: state.correct, primary: true }]}
            />
          ) : state.flow === 'known' && state.persona ? (
            <View style={styles.confirmFill}>
              <KioskPersonaCard
                nombre={nombreCompleto}
                tipo={state.persona.nom_tipo_persona || 'Registrado'}
                documento={state.documento}
              />
              <Text style={styles.confirmQuestion}>
                ¿Confirma que usted es {primerNombre}?
              </Text>
              <View style={styles.footerRow}>
                {renderGhostBtn('Corregir', state.correct, true)}
                {renderAccentBtn('Sí, soy yo', state.confirmKnown, false, true, true)}
              </View>
            </View>
          ) : (
            <KioskStatusPanel
              variant="info"
              icon="person-add-outline"
              title="Persona no registrada"
              message="No encontramos sus datos en el sistema. Complete la información en el siguiente paso."
              actions={[
                { label: 'Corregir', onPress: state.correct },
                { label: 'Continuar →', onPress: state.continueNewFromAviso, primary: true },
              ]}
            />
          )}
        </View>
      )}

      {state.step === 'datos' && (
          <ScrollView
            style={styles.datosScroll}
            contentContainerStyle={styles.datosContent}
            keyboardShouldPersistTaps="handled"
          >
            <Text style={styles.sectionLabel}>Datos de la persona</Text>
            <Text style={styles.fieldLabel}>Nombres</Text>
            <TextInput
              style={styles.fieldInput}
              value={state.nombres}
              onChangeText={state.setNombres}
              autoCapitalize="characters"
              placeholder="NOMBRES"
              placeholderTextColor={kioskTheme.muted}
            />
            <Text style={styles.fieldLabel}>Apellidos</Text>
            <TextInput
              style={styles.fieldInput}
              value={state.apellidos}
              onChangeText={state.setApellidos}
              autoCapitalize="characters"
              placeholder="APELLIDOS"
              placeholderTextColor={kioskTheme.muted}
            />
            <Text style={styles.fieldLabel}>Tipo persona</Text>
            <View style={styles.chips}>
              {state.tiposPersona.map((tp) => {
                const active = state.tipoPersona === tp.id;
                return (
                  <TouchableOpacity
                    key={tp.id}
                    style={[styles.chip, active && styles.chipActive]}
                    onPress={() => state.setTipoPersona(tp.id)}
                  >
                    <Text style={[styles.chipText, active && styles.chipTextActive]}>
                      {tp.nombre}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
            <View style={styles.footer}>
              {renderAccentBtn('Continuar →', state.continueFromDatos)}
            </View>
          </ScrollView>
      )}

      {state.step === 'puerta' && (
        <PuertaKioskStep
          mode="ingreso"
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
  datosScroll: {
    flex: 1,
  },
  datosContent: {
    paddingBottom: spacing.xl,
  },
  fieldLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: kioskTheme.label,
    marginHorizontal: kioskTheme.screenPadding,
    marginTop: spacing.sm,
    marginBottom: spacing.xs,
  },
  fieldInput: {
    marginHorizontal: kioskTheme.screenPadding,
    borderWidth: 1,
    borderColor: kioskTheme.keyBorder,
    borderRadius: 12,
    padding: spacing.lg,
    fontSize: 22,
    color: kioskTheme.keyText,
    backgroundColor: kioskTheme.displayBg,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
    paddingHorizontal: kioskTheme.screenPadding,
    marginBottom: spacing.md,
  },
  chip: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: kioskTheme.keyBorder,
    backgroundColor: kioskTheme.keyBg,
  },
  chipActive: {
    borderColor: accent,
    backgroundColor: 'rgba(0, 229, 176, 0.15)',
  },
  chipText: {
    color: kioskTheme.keyText,
    fontSize: 15,
    fontWeight: '600',
  },
  chipTextActive: {
    color: accent,
  },
});
