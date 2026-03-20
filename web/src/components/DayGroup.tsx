import { useState } from 'react';
import type { CalorieRecord } from '../types';
import styles from './DayGroup.module.css';

interface Props {
  day: string;
  records: CalorieRecord[];
  caloriesGoal: number;
  onEdit: (record: CalorieRecord) => void;
}

export function DayGroup({ day, records, caloriesGoal, onEdit }: Props) {
  const [expanded, setExpanded] = useState(false);

  const positiveTotal = records.reduce((s, r) => s + (r.value > 0 ? r.value : 0), 0);
  const netTotal = records.reduce((s, r) => s + r.value, 0);
  const proteinTotal = records.reduce((s, r) => s + (r.protein_grams ?? 0), 0);
  const fatTotal = records.reduce((s, r) => s + (r.fat_grams ?? 0), 0);
  const carbTotal = records.reduce((s, r) => s + (r.carb_grams ?? 0), 0);
  const isOver = positiveTotal > caloriesGoal;

  return (
    <>
      <tr className={styles.dayHeader} onClick={() => setExpanded(!expanded)}>
        <td colSpan={2}><strong>{day}</strong></td>
        <td className={`${styles.num} ${isOver ? styles.over : ''}`}>{positiveTotal.toFixed(0)}</td>
        <td className={styles.num}>{netTotal.toFixed(0)}</td>
        <td className={styles.num}>{proteinTotal.toFixed(1)}</td>
        <td className={styles.num}>{fatTotal.toFixed(1)}</td>
        <td className={styles.num}>{carbTotal.toFixed(1)}</td>
      </tr>
      {expanded && records.map((item) => {
        const t = new Date(item.created_at);
        const time = `${String(t.getHours()).padStart(2, '0')}:${String(t.getMinutes()).padStart(2, '0')}`;
        return (
          <tr key={item.id} className={styles.itemRow} onClick={() => onEdit(item)}>
            <td>{time}</td>
            <td>{item.description ?? ''}</td>
            <td className={styles.num}>{item.value.toFixed(0)}</td>
            <td></td>
            <td className={styles.num}>{item.protein_grams?.toFixed(1) ?? ''}</td>
            <td className={styles.num}>{item.fat_grams?.toFixed(1) ?? ''}</td>
            <td className={styles.num}>{item.carb_grams?.toFixed(1) ?? ''}</td>
          </tr>
        );
      })}
    </>
  );
}
