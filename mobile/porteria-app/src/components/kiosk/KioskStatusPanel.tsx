import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { kiosk, spacing } from '../../theme';

type IoniconName = ComponentProps<typeof Ionicons>['name'];
type Variant = 'warning' | 'info' | 'neutral';

type Action = {
  label: string;
  onPress: () => void;
  primary?: boolean;
};

type Props = {
  variant?: Variant;
  icon: IoniconName;
  title: string;
  message: string;
  actions: Action[];
  loading?: boolean;
  loadingText?: string;
};

const variantStyles: Record<
  Variant,
  { iconBg: string; iconColor: string; border: string; cardBg: string }
> = {
  warning: {
    iconBg: kiosk.warningBg,
    iconColor: kiosk.warning,
    border: kiosk.warningBorder,
    cardBg: 'rgba(20, 12, 8, 0.35)',
  },
  info: {
    iconBg: kiosk.infoBg,
    iconColor: kiosk.accent,
    border: kiosk.panelBorder,
    cardBg: kiosk.displayBg,
  },
  neutral: {
    iconBg: kiosk.keyBg,
    iconColor: kiosk.muted,
    border: kiosk.keyBorder,
    cardBg: kiosk.displayBg,
  },
};

export function KioskStatusPanel({
  variant = 'info',
  icon,
  title,
  message,
  actions,
  loading,
  loadingText,
}: Props) {
  const v = variantStyles[variant];
  const row = actions.length > 1;

  return (
    <View style={styles.wrap}>
      <View style={[styles.card, { borderColor: v.border, backgroundColor: v.cardBg }]}>
        <View style={[styles.iconRing, { backgroundColor: v.iconBg, borderColor: v.border }]}>
          {loading ? (
            <ActivityIndicator size="large" color={v.iconColor} />
          ) : (
            <Ionicons name={icon} size={40} color={v.iconColor} />
          )}
        </View>

        <Text style={styles.title}>{loading ? loadingText ?? title : title}</Text>
        {!loading && <Text style={styles.message}>{message}</Text>}

        {!loading && actions.length > 0 && (
          <View style={[styles.actions, row && styles.actionsRow]}>
            {actions.map((action) => (
              <TouchableOpacity
                key={action.label}
                style={[
                  styles.btn,
                  row && styles.btnRow,
                  action.primary ? styles.btnPrimary : styles.btnSecondary,
                ]}
                onPress={action.onPress}
                activeOpacity={0.8}
              >
                <Text
                  style={[styles.btnText, action.primary ? styles.btnTextPrimary : styles.btnTextSecondary]}
                >
                  {action.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: kiosk.screenPadding,
    paddingVertical: spacing.xl,
  },
  card: {
    borderRadius: 20,
    borderWidth: 1.5,
    paddingVertical: spacing.xl,
    paddingHorizontal: spacing.lg,
    alignItems: 'center',
  },
  iconRing: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.lg,
  },
  title: {
    fontSize: 22,
    fontWeight: '800',
    color: kiosk.keyText,
    textAlign: 'center',
    marginBottom: spacing.sm,
    letterSpacing: 0.3,
  },
  message: {
    fontSize: 16,
    lineHeight: 24,
    color: kiosk.keyText,
    opacity: 0.75,
    textAlign: 'center',
    marginBottom: spacing.lg,
    maxWidth: 320,
  },
  actions: {
    width: '100%',
    gap: spacing.sm,
    marginTop: spacing.sm,
  },
  actionsRow: {
    flexDirection: 'row',
  },
  btn: {
    paddingVertical: 16,
    paddingHorizontal: spacing.lg,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  btnRow: {
    flex: 1,
  },
  btnPrimary: {
    backgroundColor: kiosk.accent,
    borderWidth: 1.5,
    borderColor: kiosk.accent,
  },
  btnSecondary: {
    backgroundColor: kiosk.keyBg,
    borderWidth: 1,
    borderColor: kiosk.keyBorder,
  },
  btnText: {
    fontWeight: '800',
    fontSize: 16,
  },
  btnTextPrimary: {
    color: '#041210',
  },
  btnTextSecondary: {
    color: kiosk.keyText,
  },
});
