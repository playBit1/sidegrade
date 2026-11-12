import { useState } from "react";

export default function ScreenshotViewer({ productName, screenshots }) {
  const [current, setCurrent] = useState(screenshots[0]);

  return (
    <section className="viewer" aria-label="Screenshots">
      <div className="views" role="tablist" aria-label="Screens">
        {screenshots.map((shot) => (
          <button
            key={shot.id}
            type="button"
            role="tab"
            aria-selected={shot.id === current.id}
            onClick={() => setCurrent(shot)}
          >
            {shot.label}
          </button>
        ))}
      </div>
      <div className="shot">
        <img src={current.src} width="1100" height="750" alt={`${productName}: ${current.label}`} />
        <p>{current.caption}</p>
      </div>
    </section>
  );
}
