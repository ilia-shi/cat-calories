import { useCallback, useEffect, useState } from 'react';
import { fetchHome } from '../api';
import type { HomeDashboard } from '../types';

const POLL_INTERVAL = 30_000;

export function useHome() {
  const [data, setData] = useState<HomeDashboard | null>(null);
  const [online, setOnline] = useState(true);

  const poll = useCallback(async () => {
    try {
      const result = await fetchHome();
      setData(result);
      setOnline(true);
    } catch {
      setOnline(false);
    }
  }, []);

  useEffect(() => {
    poll();
    const id = setInterval(poll, POLL_INTERVAL);
    return () => clearInterval(id);
  }, [poll]);

  return { data, online, refresh: poll };
}
