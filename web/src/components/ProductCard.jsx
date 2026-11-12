import { Link } from "react-router-dom";
import { kb } from "../data/products.js";

export default function ProductCard({ product }) {
  const to = `/mods/${product.slug}`;
  return (
    <article className="card">
      <Link to={to} className="card-shot" tabIndex={-1} aria-hidden="true">
        <img src={product.cover} width="1100" height="750" alt="" loading="lazy" />
      </Link>
      <div className="card-body">
        <span className="label">For the {product.target}</span>
        <h3>
          <Link to={to}>{product.name}</Link>
        </h3>
        <p>{product.summary}</p>
        <dl className="facts">
          <div>
            <dt>Download</dt>
            <dd>{kb(product.zipBytes)} KB</dd>
          </div>
          <div>
            <dt>Installed</dt>
            <dd>{kb(product.rawBytes)} KB</dd>
          </div>
          <div>
            <dt>Files</dt>
            <dd>{product.fileCount}</dd>
          </div>
        </dl>
        <div className="actions">
          <Link to={to} className="btn">
            View mod
          </Link>
          <a className="btn quiet" href={product.download} download={product.downloadName}>
            Download
          </a>
        </div>
      </div>
    </article>
  );
}
