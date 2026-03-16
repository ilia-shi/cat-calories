import { useCallback, useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { Sidebar } from './components/Sidebar';
import { Spinner } from './components/Spinner';
import { HomePage } from './pages/HomePage';
import { CaloriesPage } from './pages/CaloriesPage';
import './App.css';

function App() {
  const location = useLocation();
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

  const transitioning = visiblePath !== location.pathname;

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
          <HomePage onLoadingChange={setHomeLoading} />
        </div>
        <div style={{ display: visiblePath === '/calories' ? 'block' : 'none' }}>
          <CaloriesPage onLoadingChange={setCaloriesLoading} />
        </div>
      </main>
    </div>
  );
}

export default App;
