import type { ApiResponse, CalorieRecord, HomeDashboard } from './types';

export async function fetchRecords(): Promise<ApiResponse> {
  const res = await fetch('/api/records');
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

export async function updateRecord(
  id: number,
  data: Partial<Pick<CalorieRecord, 'value' | 'description' | 'weight_grams' | 'protein_grams' | 'fat_grams' | 'carb_grams' | 'eaten_at' | 'created_at'>>,
): Promise<void> {
  const res = await fetch(`/api/records/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
}

export async function createRecord(data: {
  value: number;
  description?: string | null;
  eaten_at?: string | null;
  weight_grams?: number | null;
  protein_grams?: number | null;
  fat_grams?: number | null;
  carb_grams?: number | null;
}): Promise<void> {
  const res = await fetch('/api/records', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
}

export async function deleteRecord(id: number): Promise<void> {
  const res = await fetch(`/api/records/${id}`, { method: 'DELETE' });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
}

export async function fetchHome(): Promise<HomeDashboard> {
  const res = await fetch('/api/home');
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}
