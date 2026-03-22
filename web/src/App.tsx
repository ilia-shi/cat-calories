import { useCallback, useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { Sidebar } from './components/Sidebar';
import { Spinner } from './components/Spinner';
import { HomePage } from './pages/HomePage';
import { CaloriesPage } from './pages/CaloriesPage';
import { LoginPage } from './pages/LoginPage';
import { hasToken, logout, UnauthorizedError } from './api';
import './App.css';

function App() {
  const location = useLocation();
  const [authed, setAuthed] = useState(hasToken());
  const [visiblePath, setVisiblePath] = useState(location.pathname);
  const [loadingPages, setLoadingPages] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!loadingPages.has(location.pathname)) {
      setVisiblePath(location.pathname);
    }
  }, [location.pathname, loadingPages]);

  const setPageLoading = useCallback((path: string, loading: boolean) => {
    setLoadingPages(prev => {
      const next = new Set(prev);
      if (loading) next.add(path); else next.delete(path);
      return next;
    });
  }, []);

  const setHomeLoading = useCallback(
    (loading: boolean) => setPageLoading('/', loading),
    [setPageLoading],
  );

  const setCaloriesLoading = useCallback(
    (loading: boolean) => setPageLoading('/calories', loading),
    [setPageLoading],
  );

  const handleAuthError = useCallback((err: unknown) => {
    if (err instanceof UnauthorizedError) {
      logout();
      setAuthed(false);
    }
  }, []);

  const handleLogin = useCallback(() => {
    setAuthed(true);
  }, []);

  const transitioning = visiblePath !== location.pathname;

  if (!authed) {
    return <LoginPage onLogin={handleLogin} />;
  }

  return (
    <div className="app">
      <Sidebar />
      <main className="main-content">
        {transitioning && (
          <div className="page-loading-overlay">
            <Spinner />
          </div>
        )}
        <div style={{ display: visiblePath === '/' ? 'block' : 'none' }}>
          <HomePage onLoadingChange={setHomeLoading} onAuthError={handleAuthError} />
        </div>
        <div style={{ display: visiblePath === '/calories' ? 'block' : 'none' }}>
          <CaloriesPage onLoadingChange={setCaloriesLoading} onAuthError={handleAuthError} />
        </div>
      </main>
    </div>
  );
}

export default App;
