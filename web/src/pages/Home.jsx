import { useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import ProductCard from "../components/ProductCard.jsx";
import { products } from "../data/products.js";

const promises = [
  {
    title: "Reversible",
    text: (
      <>
        Every installer backs up the files it replaces first, and <code>--uninstall</code> puts them back.
      </>
    ),
  },
  {
    title: "Checked against your version",
    text: "If your dotfiles differ from the version a mod was built on, the installer stops and says which files.",
  },
  {
    title: "Nothing hidden",
    text: "A mod is a zip of plain config files and a short shell script you can read before running. No root, no packages.",
  },
];

const steps = [
  { title: "Download the zip", text: "Each mod is one small archive." },
  { title: "Unzip and run install.sh", text: "It checks your dotfiles version, backs up, then copies the files in." },
  { title: "Reopen the app it changes", text: "The rest of your desktop keeps running." },
];

export default function Home() {
  // "/#mods" style links: scroll to the section once the page is rendered
  const { hash } = useLocation();
  useEffect(() => {
    if (hash) document.getElementById(hash.slice(1))?.scrollIntoView();
  }, [hash]);

  return (
    <div className="stack">
      <section className="hero">
        <div className="hero-copy">
          <span className="label">Unofficial mods for end-4's dots-hyprland</span>
          <h1>Small upgrades for a desktop you already like.</h1>
          <p>
            Sidegrade makes focused mods for end-4's Hyprland dotfiles. Each one changes a single part of the setup,
            installs with one script, and can be removed just as easily.
          </p>
          <div className="actions">
            <Link to={`/mods/${products[0].slug}`} className="btn">
              See the first mod
            </Link>
            <Link to="/#how" className="btn quiet">
              How installing works
            </Link>
          </div>
        </div>
        <div className="promises">
          {promises.map((promise) => (
            <div key={promise.title}>
              <h3>{promise.title}</h3>
              <p>{promise.text}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="section" id="mods">
        <div className="section-head">
          <h2>Mods</h2>
          <span className="label">
            {products.length} available · more for end-4 configs to come
          </span>
        </div>
        <div className="catalog">
          {products.map((product) => (
            <ProductCard key={product.slug} product={product} />
          ))}
        </div>
      </section>

      <section className="section" id="how">
        <h2>How installing works</h2>
        <ol className="steps">
          {steps.map((step) => (
            <li key={step.title}>
              <div className="body">
                <h3>{step.title}</h3>
                <p>{step.text}</p>
              </div>
            </li>
          ))}
        </ol>
      </section>
    </div>
  );
}
