import { NavLink } from 'react-router-dom';

export function Sidebar() {
  return (
    <nav className="sidebar">
      <div className="sidebar-header">Cat Calories</div>
      <ul className="sidebar-nav">
        <li>
          <NavLink to="/" end>
            Home
          </NavLink>
        </li>
        <li>
          <NavLink to="/calories">
            Calories
          </NavLink>
        </li>
      </ul>
    </nav>
  );
}
