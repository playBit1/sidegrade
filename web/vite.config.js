import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Relative base + hash routing: the built site works from any folder on any static host.
export default defineConfig({
  base: "./",
  plugins: [react()],
});
