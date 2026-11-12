# Sidegrade

Storefront for unofficial mods for end-4's dots-hyprland. React + Vite, hash routing, no backend.

```
npm install
npm run dev       # http://localhost:5173
npm run build     # static site in dist/, works from any folder on any static host
```

- `src/data/products.js` is the catalog. Add a product object there to list another mod.
- `src/data/settings-rework.generated.json`, `public/downloads/` and `public/shots/` are written by
  `../build_site.py`, which builds the zip from `../patched/`. Run it before `npm run build` when the mod changes.
- Pages: `src/pages/Home.jsx` (landing + catalog), `src/pages/Product.jsx` (one mod, at `#/mods/<slug>`).
