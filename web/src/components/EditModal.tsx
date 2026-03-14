import { useState } from 'react';
import type { CalorieRecord } from '../types';
import { updateRecord, deleteRecord } from '../api';
import styles from './EditModal.module.css';

interface Props {
  record: CalorieRecord;
  onClose: () => void;
  onSaved: () => void;
}

export function EditModal({ record, onClose, onSaved }: Props) {
  const [value, setValue] = useState(String(record.value));
  const [description, setDescription] = useState(record.description ?? '');
  const [weightGrams, setWeightGrams] = useState(record.weight_grams != null ? String(record.weight_grams) : '');
  const [proteinGrams, setProteinGrams] = useState(record.protein_grams != null ? String(record.protein_grams) : '');
  const [fatGrams, setFatGrams] = useState(record.fat_grams != null ? String(record.fat_grams) : '');
  const [carbGrams, setCarbGrams] = useState(record.carb_grams != null ? String(record.carb_grams) : '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function handleSave() {
    const numValue = parseFloat(value);
    if (isNaN(numValue)) {
      setError('Calories must be a number');
      return;
    }

    setSaving(true);
    setError('');
    try {
      await updateRecord(record.id, {
        value: numValue,
        description: description || null,
        weight_grams: weightGrams ? parseFloat(weightGrams) : null,
        protein_grams: proteinGrams ? parseFloat(proteinGrams) : null,
        fat_grams: fatGrams ? parseFloat(fatGrams) : null,
        carb_grams: carbGrams ? parseFloat(carbGrams) : null,
      });
      onSaved();
    } catch (e) {
      setError(String(e));
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!confirm('Delete this record?')) return;
    setSaving(true);
    try {
      await deleteRecord(record.id);
      onSaved();
    } catch (e) {
      setError(String(e));
      setSaving(false);
    }
  }

  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={e => e.stopPropagation()}>
        <h2>Edit Record</h2>

        {error && <div className={styles.error}>{error}</div>}

        <label>
          Calories (kcal)
          <input
            type="number"
            value={value}
            onChange={e => setValue(e.target.value)}
            autoFocus
          />
        </label>

        <label>
          Description
          <input
            type="text"
            value={description}
            onChange={e => setDescription(e.target.value)}
          />
        </label>

        <div className={styles.row}>
          <label>
            Weight (g)
            <input
              type="number"
              value={weightGrams}
              onChange={e => setWeightGrams(e.target.value)}
            />
          </label>
          <label>
            Protein (g)
            <input
              type="number"
              value={proteinGrams}
              onChange={e => setProteinGrams(e.target.value)}
            />
          </label>
        </div>

        <div className={styles.row}>
          <label>
            Fat (g)
            <input
              type="number"
              value={fatGrams}
              onChange={e => setFatGrams(e.target.value)}
            />
          </label>
          <label>
            Carbs (g)
            <input
              type="number"
              value={carbGrams}
              onChange={e => setCarbGrams(e.target.value)}
            />
          </label>
        </div>

        <div className={styles.actions}>
          <button className={styles.deleteBtn} onClick={handleDelete} disabled={saving}>
            Delete
          </button>
          <div className={styles.rightActions}>
            <button className={styles.cancelBtn} onClick={onClose} disabled={saving}>
              Cancel
            </button>
            <button className={styles.saveBtn} onClick={handleSave} disabled={saving}>
              {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
