import { View, Text, StyleSheet, Platform } from 'react-native';
import { kiosk, spacing } from '../../theme';

const MAX_DIGITS = 10;

const EMPTY_PLACEHOLDER = Array.from({ length: MAX_DIGITS }, () => '—').join(' ');

type Props = {
  documento: string;
};

export function DocumentDisplay({ documento }: Props) {
  const empty = documento.length === 0;
  const remaining = Math.max(0, MAX_DIGITS - documento.length);
  const trailingPlaceholder =
    remaining > 0 ? ` ${Array.from({ length: remaining }, () => '—').join(' ')}` : '';

  return (
    <View style={styles.wrap}>
      <View style={styles.numWrap}>
        {empty ? (
          <Text
            style={[styles.num, styles.placeholder]}
            numberOfLines={1}
            adjustsFontSizeToFit
            minimumFontScale={0.5}
            allowFontScaling={false}
          >
            {EMPTY_PLACEHOLDER}
          </Text>
        ) : (
          <Text
            style={styles.numRow}
            numberOfLines={1}
            adjustsFontSizeToFit
            minimumFontScale={kiosk.numFontSizeMin / kiosk.numFontSize}
            allowFontScaling={false}
          >
            <Text style={styles.num}>{documento}</Text>
            {remaining > 0 && (
              <Text style={[styles.num, styles.placeholder]}>{trailingPlaceholder}</Text>
            )}
          </Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: kiosk.displayBg,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: kiosk.keyBorder,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.lg,
    marginHorizontal: kiosk.screenPadding,
    marginBottom: spacing.md,
    minHeight: 72,
  },
  numWrap: {
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  numRow: {
    width: '100%',
    fontSize: kiosk.numFontSize,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
    textAlign: 'center',
    ...(Platform.OS === 'android' ? { includeFontPadding: false } : {}),
  },
  num: {
    fontSize: kiosk.numFontSize,
    fontWeight: '700',
    color: kiosk.numColor,
    fontVariant: ['tabular-nums'],
    letterSpacing: 1,
    textAlign: 'center',
    ...(Platform.OS === 'android' ? { includeFontPadding: false } : {}),
  },
  placeholder: {
    color: kiosk.muted,
    letterSpacing: 2,
    fontSize: 26,
    textAlign: 'center',
    width: '100%',
  },
});
