import { useRef, useState } from "react";

// A shell command with a Copy button. Falls back to selecting the text if the clipboard is unavailable.
export default function CopyCommand({ children }) {
  const pre = useRef(null);
  const [label, setLabel] = useState("Copy");

  const select = () => {
    const range = document.createRange();
    range.selectNodeContents(pre.current);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    setLabel("Selected");
  };

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(pre.current.textContent);
      setLabel("Copied");
      setTimeout(() => setLabel("Copy"), 1500);
    } catch {
      select();
    }
  };

  return (
    <div className="cmd">
      <pre ref={pre}>{children}</pre>
      <button type="button" onClick={copy}>
        {label}
      </button>
    </div>
  );
}
