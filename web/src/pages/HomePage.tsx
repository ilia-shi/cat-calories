import { useEffect } from 'react';
import { useHome } from '../hooks/useHome';
import { Spinner } from '../components/Spinner';
import type { RecentMeal } from '../types';

function formatKcal(value: number): string {
  return Math.round(value).toLocaleString();
}

function timeAgo(isoDate: string): string {
  const diff = Date.now() - new Date(isoDate).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ${mins % 60}m ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

function MealRow({ meal }: { meal: RecentMeal }) {
  return (
    <tr>
      <td className="home-meal-time">{timeAgo(meal.eaten_at)}</td>
      <td>{meal.description || '—'}</td>
      <td className="num">{formatKcal(meal.value)}</td>
    </tr>
  );
}

interface Props {
  onLoadingChange: (loading: boolean) => void;
}

export function HomePage({ onLoadingChange }: Props) {
  const { data, online } = useHome();

  const loading = !data;
  useEffect(() => {
    onLoadingChange(loading);
  }, [loading, onLoadingChange]);

  if (!data) {
    return (
      <div className="page-spinner-container">
        <Spinner />
      </div>
    );
  }

  const goal = data.profile.calories_limit_goal;

  return (
    <div className="home-page">
      <header>
        <span className={`status ${online ? 'live' : ''}`}>
          {online ? 'live' : 'offline'}
        </span>
        <h1>{data.profile.name}</h1>
        <p className="subtitle">Goal: {formatKcal(goal)} kcal/day</p>
      </header>

      <div className="home-indicators">
        <Indicator
          label="24h Rolling"
          value={data.rolling_24h}
          goal={goal}
        />
        <Indicator
          label="Today"
          value={data.today}
          goal={goal}
        />
        <Indicator
          label="Yesterday"
          value={data.yesterday}
          goal={goal}
        />
        <Indicator
          label="7-Day Avg"
          value={data.avg_7_days}
          goal={goal}
        />
        {data.period && (
          <Indicator
            label="Period"
            value={data.period.calories}
            goal={data.period.goal}
          />
        )}
      </div>

      <section className="home-recent">
        <h2>Recent Meals (24h)</h2>
        {data.recent_meals.length === 0 ? (
          <p className="home-empty">No meals in the last 24 hours</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>When</th>
                <th>Description</th>
                <th className="num">kcal</th>
              </tr>
            </thead>
            <tbody>
              {data.recent_meals.map((meal) => (
                <MealRow key={meal.id} meal={meal} />
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}

function Indicator({
  label,
  value,
  goal,
}: {
  label: string;
  value: number;
  goal: number;
}) {
  const pct = goal > 0 ? (value / goal) * 100 : 0;
  const over = pct > 100;

  return (
    <div className={`home-indicator ${over ? 'over' : ''}`}>
      <span className="home-indicator-label">{label}</span>
      <span className="home-indicator-value">{formatKcal(value)}</span>
      <span className="home-indicator-pct">{Math.round(pct)}%</span>
      <div className="home-indicator-bar">
        <div
          className="home-indicator-fill"
          style={{ width: `${Math.min(pct, 100)}%` }}
        />
      </div>
    </div>
  );
}
