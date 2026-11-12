import { Link } from "react-router-dom";

export default function Header() {
  return (
    <header className="top">
      <Link to="/" className="brand">
        Sidegrade
      </Link>
      <nav className="nav" aria-label="Main">
        <Link to="/#mods">Mods</Link>
        <Link to="/#how">How installing works</Link>
      </nav>
    </header>
  );
}
