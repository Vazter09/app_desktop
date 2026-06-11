import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
} from 'react-native';
import { colors, spacing } from '../theme';

type Entrada = { id: number; nombre: string };

type Props = {
  entradas: Entrada[];
  selected: number;
  onSelect: (id: number) => void;
};

export function PuertaGrid({ entradas, selected, onSelect }: Props) {
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.row}>
      {entradas.map((e) => {
        const active = selected === e.id;
        return (
          <TouchableOpacity
            key={e.id}
            style={[styles.btn, active && styles.btnActive]}
            onPress={() => onSelect(e.id)}
          >
            <Text style={[styles.btnText, active && styles.btnTextActive]}>{e.id}</Text>
            <Text style={[styles.sub, active && styles.btnTextActive]} numberOfLines={1}>
              {e.nombre}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  row: { flexGrow: 0, marginVertical: spacing.sm },
  btn: {
    minWidth: 88,
    padding: spacing.md,
    marginRight: spacing.sm,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: colors.border,
    backgroundColor: colors.card,
    alignItems: 'center',
  },
  btnActive: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  btnText: { fontSize: 22, fontWeight: '700', color: colors.text },
  btnTextActive: { color: '#fff' },
  sub: { fontSize: 11, color: colors.muted, marginTop: 4, maxWidth: 80 },
});
