import { useState } from 'react';
import { createRecord } from '../api';
import styles from './EditModal.module.css';

interface Props {
  onClose: () => void;
  onSaved: () => void;
}

export function AddModal({ onClose, onSaved }: Props) {
  const [value, setValue] = useState('');
  const [description, setDescription] = useState('');
  const [eatenAt, setEatenAt] = useState('');
  const [weightGrams, setWeightGrams] = useState('');
  const [proteinGrams, setProteinGrams] = useState('');
  const [fatGrams, setFatGrams] = useState('');
  const [carbGrams, setCarbGrams] = useState('');
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
      await createRecord({
        value: numValue,
        description: description || null,
        eaten_at: eatenAt || null,
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

  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={e => e.stopPropagation()}>
        <h2>Add Record</h2>

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

        <label>
          Date & Time
          <input
            type="datetime-local"
            value={eatenAt}
            onChange={e => setEatenAt(e.target.value)}
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
          <div></div>
          <div className={styles.rightActions}>
            <button className={styles.cancelBtn} onClick={onClose} disabled={saving}>
              Cancel
            </button>
            <button className={styles.saveBtn} onClick={handleSave} disabled={saving}>
              {saving ? 'Adding...' : 'Add'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
