import { useEffect, useState } from 'react';
import { subscribeSync, startSyncEngine, stopSyncEngine } from '../sync/SyncEngine';

export function useNetworkStatus(): { online: boolean; pending: number } {
  const [online, setOnline] = useState(true);
  const [pending, setPending] = useState(0);

  useEffect(() => {
    startSyncEngine();
    const unsub = subscribeSync((isOnline, pendingCount) => {
      setOnline(isOnline);
      setPending(pendingCount);
    });
    return () => {
      unsub();
      stopSyncEngine();
    };
  }, []);

  return { online, pending };
}
