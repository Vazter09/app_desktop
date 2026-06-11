import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { kiosk, spacing } from '../../theme';

type Props = {
  onDigit: (d: string) => void;
  onDelete: () => void;
  disabled?: boolean;
  fill?: boolean;
};

const ROWS = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
];

export function NumericKeypad({ onDigit, onDelete, disabled, fill }: Props) {
  return (
    <View style={[styles.wrap, fill && styles.wrapFill]}>
      {ROWS.map((row) => (
        <View key={row.join('')} style={[styles.row, fill && styles.rowFill]}>
          {row.map((d) => (
            <TouchableOpacity
              key={d}
              style={[styles.key, fill && styles.keyFill]}
              onPress={() => onDigit(d)}
              disabled={disabled}
              activeOpacity={0.65}
            >
              <Text style={styles.keyText}>{d}</Text>
            </TouchableOpacity>
          ))}
        </View>
      ))}
      <View style={[styles.row, fill && styles.rowFill]}>
        <TouchableOpacity
          style={[styles.key, styles.zero, fill && styles.keyFill]}
          onPress={() => onDigit('0')}
          disabled={disabled}
          activeOpacity={0.65}
        >
          <Text style={styles.keyText}>0</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.key, styles.del, fill && styles.keyFill]}
          onPress={onDelete}
          disabled={disabled}
          activeOpacity={0.65}
        >
          <Text style={styles.delText}>⌫</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    paddingHorizontal: kiosk.screenPadding,
    gap: spacing.sm,
  },
  wrapFill: {
    flex: 1,
    paddingVertical: spacing.sm,
    gap: spacing.md,
  },
  row: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  rowFill: {
    flex: 1,
  },
  key: {
    flex: 1,
    minHeight: 56,
    backgroundColor: kiosk.keyBg,
    borderWidth: 1,
    borderColor: kiosk.keyBorder,
    borderRadius: 13,
    alignItems: 'center',
    justifyContent: 'center',
  },
  keyFill: {
    minHeight: 0,
  },
  zero: {
    flex: 2,
  },
  del: {
    flex: 1,
  },
  keyText: {
    fontSize: kiosk.keyFontSize,
    fontWeight: '600',
    color: kiosk.keyText,
  },
  delText: {
    fontSize: 30,
    fontWeight: '600',
    color: kiosk.deleteColor,
  },
});
