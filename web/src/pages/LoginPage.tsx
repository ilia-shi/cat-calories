import { type FormEvent, useState } from 'react';
import { login } from '../api';

interface Props {
  onLogin: () => void;
}

export function LoginPage({ onLogin }: Props) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      onLogin();
    } catch {
      setError('Invalid email or password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <form className="login-form" onSubmit={handleSubmit}>
        <h1 className="login-title">Cat Calories</h1>
        {error && <div className="login-error">{error}</div>}
        <label className="login-label">
          Email
          <input
            type="email"
            className="login-input"
            value={email}
            onChange={e => setEmail(e.target.value)}
            autoFocus
            required
          />
        </label>
        <label className="login-label">
          Password
          <input
            type="password"
            className="login-input"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
          />
        </label>
        <button type="submit" className="login-btn" disabled={loading}>
          {loading ? 'Signing in...' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
