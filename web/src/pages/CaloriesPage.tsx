import { useEffect, useMemo, useState } from 'react';
import { useRecords } from '../hooks/useRecords';
import { DayGroup } from '../components/DayGroup';
import { EditModal } from '../components/EditModal';
import { AddModal } from '../components/AddModal';
import { Spinner } from '../components/Spinner';
import type { CalorieRecord } from '../types';

function groupByDay(records: CalorieRecord[]): Map<string, CalorieRecord[]> {
  const days = new Map<string, CalorieRecord[]>();
  for (const r of records) {
    const day = r.created_at.slice(0, 10);
    if (!days.has(day)) days.set(day, []);
    days.get(day)!.push(r);
  }
  return days;
}

interface Props {
  onLoadingChange: (loading: boolean) => void;
  onAuthError?: (err: unknown) => void;
}

export function CaloriesPage({ onLoadingChange, onAuthError }: Props) {
  const { data, online, refresh } = useRecords(onAuthError);
  const [editing, setEditing] = useState<CalorieRecord | null>(null);
  const [adding, setAdding] = useState(false);

  const loading = !data;
  useEffect(() => {
    onLoadingChange(loading);
  }, [loading, onLoadingChange]);

  const days = useMemo(
    () => (data ? groupByDay(data.records) : new Map()),
    [data],
  );

  if (!data) {
    return (
      <div className="page-spinner-container">
        <Spinner />
      </div>
    );
  }

  return (
    <div className="calories-page">
      <header>
        <span className={`status ${online ? 'live' : ''}`}>
          {online ? 'live' : 'offline'}
        </span>
        <h1>{data.profile.name}</h1>
        <p className="subtitle">
          Goal: {data.profile.calories_limit_goal.toFixed(0)} kcal/day
          <button className="add-btn" onClick={() => setAdding(true)}>+ Add</button>
        </p>
      </header>

      <table>
        <thead>
          <tr>
            <th>Time</th>
            <th>Description</th>
            <th className="num">kcal</th>
            <th className="num">Net</th>
            <th className="num">P (g)</th>
            <th className="num">F (g)</th>
            <th className="num">C (g)</th>
          </tr>
        </thead>
        <tbody>
          {[...days.entries()].map(([day, records]) => (
            <DayGroup
              key={day}
              day={day}
              records={records}
              caloriesGoal={data.profile.calories_limit_goal}
              onEdit={setEditing}
            />
          ))}
        </tbody>
      </table>

      {editing && (
        <EditModal
          record={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            refresh();
          }}
        />
      )}

      {adding && (
        <AddModal
          onClose={() => setAdding(false)}
          onSaved={() => {
            setAdding(false);
            refresh();
          }}
        />
      )}
    </div>
  );
}
