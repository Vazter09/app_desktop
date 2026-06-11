import { useEffect, useState } from 'react';
import type { Catalogos } from '../types';
import { fetchCatalogos } from '../api/client';
import { loadCatalogosCache, saveCatalogosCache } from '../db/schema';
import { checkHealth } from '../api/client';

export function useCatalogos(): {
  catalogos: Catalogos | null;
  loading: boolean;
  refresh: () => Promise<void>;
} {
  const [catalogos, setCatalogos] = useState<Catalogos | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = async () => {
    setLoading(true);
    try {
      const online = await checkHealth();
      if (online) {
        const res = await fetchCatalogos();
        if (res.ok) {
          setCatalogos(res.data);
          await saveCatalogosCache(JSON.stringify(res.data));
          return;
        }
      }
      const cached = await loadCatalogosCache();
      if (cached) {
        setCatalogos(JSON.parse(cached) as Catalogos);
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void refresh();
  }, []);

  return { catalogos, loading, refresh };
}
