import { useCallback, useEffect, useState } from 'react';
import { fetchRecords } from '../api';
import type { ApiResponse } from '../types';

const POLL_INTERVAL = 3000;

export function useRecords() {
  const [data, setData] = useState<ApiResponse | null>(null);
  const [online, setOnline] = useState(true);

  const poll = useCallback(async () => {
    try {
      const result = await fetchRecords();
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
