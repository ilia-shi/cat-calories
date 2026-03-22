import type { ApiResponse, CalorieRecord, HomeDashboard } from './types';

export class UnauthorizedError extends Error {
  constructor() { super('Unauthorized'); this.name = 'UnauthorizedError'; }
}

function authHeaders(): Record<string, string> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  const token = localStorage.getItem('token');
  if (token) headers['Authorization'] = `Bearer ${token}`;
  return headers;
}

function checkAuth(res: Response): void {
  if (res.status === 401) throw new UnauthorizedError();
}

export async function login(email: string, password: string): Promise<string> {
  const res = await fetch('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const data = await res.json();
  const token = data.token as string;
  localStorage.setItem('token', token);
  return token;
}

export function logout(): void {
  localStorage.removeItem('token');
}

export function hasToken(): boolean {
  return !!localStorage.getItem('token');
}

export async function fetchRecords(): Promise<ApiResponse> {
  const res = await fetch('/api/records', { headers: authHeaders() });
  checkAuth(res);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

export async function updateRecord(
  id: string,
  data: Partial<Pick<CalorieRecord, 'value' | 'description' | 'weight_grams' | 'protein_grams' | 'fat_grams' | 'carb_grams' | 'eaten_at' | 'created_at'>>,
): Promise<void> {
  const res = await fetch(`/api/records/${id}`, {
    method: 'PUT',
    headers: authHeaders(),
    body: JSON.stringify(data),
  });
  checkAuth(res);
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
    headers: authHeaders(),
    body: JSON.stringify(data),
  });
  checkAuth(res);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
}

export async function deleteRecord(id: string): Promise<void> {
  const res = await fetch(`/api/records/${id}`, {
    method: 'DELETE',
    headers: authHeaders(),
  });
  checkAuth(res);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
}

export async function fetchHome(): Promise<HomeDashboard> {
  const res = await fetch('/api/home', { headers: authHeaders() });
  checkAuth(res);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}
