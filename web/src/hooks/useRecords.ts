import { useCallback, useEffect, useState } from 'react';
import { fetchRecords, UnauthorizedError } from '../api';
import type { ApiResponse } from '../types';

const POLL_INTERVAL = 3000;

export function useRecords(onAuthError?: (err: unknown) => void) {
  const [data, setData] = useState<ApiResponse | null>(null);
  const [online, setOnline] = useState(true);

  const poll = useCallback(async () => {
    try {
      const result = await fetchRecords();
      setData(result);
      setOnline(true);
    } catch (err) {
      if (err instanceof UnauthorizedError) {
        onAuthError?.(err);
      } else {
        setOnline(false);
      }
    }
  }, [onAuthError]);

  useEffect(() => {
    poll();
    const id = setInterval(poll, POLL_INTERVAL);
    return () => clearInterval(id);
  }, [poll]);

  return { data, online, refresh: poll };
}
