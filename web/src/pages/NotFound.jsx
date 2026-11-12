import { Link } from "react-router-dom";

export default function NotFound() {
  return (
    <div className="stack">
      <section className="section">
        <h1>That page does not exist.</h1>
        <p className="muted">The mod may have been renamed or removed.</p>
        <div className="actions">
          <Link to="/" className="btn">
            Back to all mods
          </Link>
        </div>
      </section>
    </div>
  );
}
