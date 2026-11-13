import { Link, useParams } from "react-router-dom";
import CopyCommand from "../components/CopyCommand.jsx";
import ScreenshotViewer from "../components/ScreenshotViewer.jsx";
import { findProduct, kb } from "../data/products.js";
import NotFound from "./NotFound.jsx";

// Text from products.js, with `backticks` turned into <code>
const rich = (text) =>
  text.split("`").map((part, index) => (index % 2 ? <code key={index}>{part}</code> : part));

export default function Product() {
  const { slug } = useParams();
  const product = findProduct(slug);
  if (!product) return <NotFound />;

  const zipKb = kb(product.zipBytes);
  const rawKb = kb(product.rawBytes);

  return (
    <div className="stack">
      <section className="hero">
        <div className="hero-copy">
          <Link to="/#mods" className="label back">
            Back to all mods
          </Link>
          <span className="label">{product.name} · for the {product.target}</span>
          <h1>{product.tagline}</h1>
          {product.description.map((paragraph) => (
            <p key={paragraph}>{paragraph}</p>
          ))}
          <div className="actions">
            <a className="btn" href={product.download} download={product.downloadName}>
              Download · {zipKb} KB
            </a>
            <a className="btn quiet" href="#install" onClick={(event) => {
              event.preventDefault(); // "#install" would otherwise be read as a route
              document.getElementById("install")?.scrollIntoView();
            }}>
              How to install
            </a>
          </div>
        </div>
        <div className="plate" aria-label="Package size">
          <div>
            <span className="num">
              {zipKb}
              <small>KB</small>
            </span>
            <span className="label">Download (zip)</span>
          </div>
          <div>
            <span className="num">
              {rawKb}
              <small>KB</small>
            </span>
            <span className="label">Installed on disk</span>
          </div>
          <div>
            <span className="num">{product.fileCount}</span>
            <span className="label">Files</span>
          </div>
          <div>
            <span className="num">{product.fourthFact.value}</span>
            <span className="label">{product.fourthFact.label}</span>
          </div>
        </div>
      </section>

      <ScreenshotViewer productName={product.name} screenshots={product.screenshots} />

      <section className="section">
        <h2>What changes</h2>
        <div className="changes">
          {product.changes.map((change) => (
            <div key={change.title}>
              <h3>{change.title}</h3>
              <p>{change.text}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="section" id="install">
        <h2>Install</h2>
        <ol className="steps">
          <li>
            <div className="body">
              <h3>Download the zip</h3>
              <p>
                <a href={product.download} download={product.downloadName}>
                  {product.downloadName}
                </a>{" "}
                is {zipKb} KB. The install script inside is plain bash you can read first.
              </p>
            </div>
          </li>
          {product.installSteps.map((step) => (
            <li key={step.title}>
              <div className="body">
                <h3>{step.title}</h3>
                {step.command && <CopyCommand>{step.command}</CopyCommand>}
                <p>{rich(step.text)}</p>
              </div>
            </li>
          ))}
        </ol>
        <div className="notes">
          {product.notes.map((note) => (
            <div key={note.title}>
              <h3>{note.title}</h3>
              {note.command && <CopyCommand>{note.command}</CopyCommand>}
              <p>{rich(note.text)}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="section">
        <h2>What is in the download</h2>
        <div className="table">
          <table>
            <thead>
              <tr>
                <th>Files</th>
                <th>What they are</th>
                <th className="n">Count</th>
                <th className="n">Size</th>
              </tr>
            </thead>
            <tbody>
              {product.groups.map((group) => (
                <tr key={group.files}>
                  <td>{group.files}</td>
                  <td className="what">{group.what}</td>
                  <td className="n">{group.count}</td>
                  <td className="n">{kb(group.bytes)} KB</td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td>Total installed</td>
                <td></td>
                <td className="n">{product.fileCount}</td>
                <td className="n">{rawKb} KB</td>
              </tr>
            </tfoot>
          </table>
        </div>
        <p className="footnote">{product.footnote}</p>
      </section>
    </div>
  );
}
