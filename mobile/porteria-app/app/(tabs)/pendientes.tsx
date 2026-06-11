import { useCallback, useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  FlatList,
  Alert,
  RefreshControl,
} from 'react-native';
import { OfflineBanner } from '../../src/components/OfflineBanner';
import { useNetworkStatus } from '../../src/hooks/useNetworkStatus';
import { listFailedOps, resetFailedToPending } from '../../src/db/schema';
import { runSync } from '../../src/sync/SyncEngine';
import { colors, spacing } from '../../src/theme';

type FailedRow = {
  client_id: string;
  tipo: string;
  payload_json: string;
  error: string | null;
  created_at: string;
};

export default function PendientesScreen() {
  const { online, pending } = useNetworkStatus();
  const [items, setItems] = useState<FailedRow[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    const rows = await listFailedOps();
    setItems(rows);
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await runSync();
    await load();
    setRefreshing(false);
  };

  useEffect(() => {
    void load();
  }, [load]);

  const reintentar = async (clientId: string) => {
    await resetFailedToPending(clientId);
    const n = await runSync();
    Alert.alert('Sync', n > 0 ? `${n} operación(es) sincronizada(s).` : 'Sin cambios.');
    await load();
  };

  return (
    <View style={styles.flex}>
      <OfflineBanner online={online} pending={pending} />
      <View style={styles.header}>
        <Text style={styles.title}>Operaciones con error</Text>
        <TouchableOpacity style={styles.btn} onPress={() => void onRefresh()}>
          <Text style={styles.btnText}>Sincronizar ahora</Text>
        </TouchableOpacity>
      </View>
      <FlatList
        data={items}
        keyExtractor={(item) => item.client_id}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => void onRefresh()} />}
        ListEmptyComponent={
          <Text style={styles.empty}>No hay operaciones fallidas.</Text>
        }
        renderItem={({ item }) => {
          let doc = '';
          try {
            const p = JSON.parse(item.payload_json) as { documento?: string };
            doc = p.documento ?? '';
          } catch {
            /* ignore */
          }
          return (
            <View style={styles.card}>
              <Text style={styles.cardTitle}>
                {item.tipo.toUpperCase()} — doc {doc}
              </Text>
              <Text style={styles.error}>{item.error ?? 'Error desconocido'}</Text>
              <Text style={styles.date}>{item.created_at}</Text>
              <TouchableOpacity onPress={() => void reintentar(item.client_id)}>
                <Text style={styles.link}>Reintentar</Text>
              </TouchableOpacity>
            </View>
          );
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.bg },
  header: { padding: spacing.md, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  title: { fontSize: 18, fontWeight: '700', color: colors.primary },
  btn: { backgroundColor: colors.primary, paddingHorizontal: spacing.md, paddingVertical: spacing.sm, borderRadius: 8 },
  btnText: { color: '#fff', fontWeight: '600' },
  empty: { textAlign: 'center', color: colors.muted, marginTop: spacing.xl },
  card: {
    marginHorizontal: spacing.md,
    marginBottom: spacing.sm,
    padding: spacing.md,
    backgroundColor: colors.card,
    borderRadius: 8,
    borderLeftWidth: 4,
    borderLeftColor: colors.danger,
  },
  cardTitle: { fontWeight: '700', marginBottom: spacing.xs },
  error: { color: colors.danger, marginBottom: spacing.xs },
  date: { color: colors.muted, fontSize: 12 },
  link: { color: colors.primary, fontWeight: '600', marginTop: spacing.sm },
});
