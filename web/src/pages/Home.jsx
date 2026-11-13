import { useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import ProductCard from "../components/ProductCard.jsx";
import { products } from "../data/products.js";

const promises = [
  {
    title: "Reversible",
    text: (
      <>
        Every installer has an <code>--uninstall</code> that puts things back as they were, from a backup where it
        replaced files.
      </>
    ),
  },
  {
    title: "Checked against your version",
    text: "A mod that replaces dotfiles stops if yours differ from the version it was built on, and says which files.",
  },
  {
    title: "Nothing hidden",
    text: "A mod is a zip of plain config files and a short shell script you can read before running. No packages, and its page says so if it needs root.",
  },
];

const steps = [
  { title: "Download the zip", text: "Each mod is one small archive." },
  { title: "Unzip and run install.sh", text: "It checks what it is about to change, backs up, then copies the files in." },
  { title: "Reopen what it changes", text: "Usually one app. The rest of your desktop keeps running." },
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
            <Link to="/#mods" className="btn">
              See the mods
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
