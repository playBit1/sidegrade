// The catalog. Sizes and file counts come from build_site.py (settings-rework.generated.json),
// so they always describe the zip that is actually in public/downloads.
import settingsRework from "./settings-rework.generated.json";

const asset = (path) => `${import.meta.env.BASE_URL}${path}`;

export const kb = (bytes) => Math.round(bytes / 1024);

export const products = [
  {
    slug: "settings-rework",
    name: "ii Settings Rework",
    target: 'Quickshell "ii" settings app',
    tagline: "Every option in the settings app. Findable.",
    summary:
      "Gives all 284 config options a control, adds search and section navigation, and tidies the layout of the illogical-impulse settings app.",
    description: [
      "The stock illogical-impulse settings app leaves 114 of its 284 options to be edited by hand in config.json.",
      "This rework gives each of them a control, adds search and section navigation, and tidies the layout without changing how the app feels.",
    ],
    download: asset("downloads/ii-settings-rework.zip"),
    downloadName: "ii-settings-rework.zip",
    folder: "ii-settings-rework",
    backupPath: "~/.local/share/ii-settings-rework/backup",
    installPath: "~/.config/quickshell/ii",
    builtAgainstDate: "15 Aug 2026",
    ...settingsRework,
    cover: asset("shots/bar.png"),
    screenshots: [
      {
        id: "bar",
        label: "Sections and cards",
        src: asset("shots/bar.png"),
        caption:
          "The Bar page. Sections sit on faint cards, the rail lists the page's sections and marks the one in view, and units sit beside the number boxes.",
      },
      {
        id: "search",
        label: "Search",
        src: asset("shots/search.png"),
        caption:
          "Typing in the search field replaces the page list with matches from every page, each with its page and section. Ctrl+F focuses it.",
      },
      {
        id: "jump",
        label: "Jump to an option",
        src: asset("shots/jump.png"),
        caption:
          "Picking a result opens the page, scrolls to the option and highlights it for a moment. Opacity options are sliders.",
      },
      {
        id: "rows",
        label: "Newly exposed options",
        src: asset("shots/rows.png"),
        caption: "Default apps, one of the newly exposed groups. Short values use a compact row with the label on the left.",
      },
      {
        id: "quick",
        label: "Quick page",
        src: asset("shots/quick.png"),
        caption:
          "The Quick page keeps its wallpaper and color controls. The Waffle tab only appears while that panel family is active.",
      },
    ],
    changes: [
      {
        title: "All 284 options have a control",
        text: "Default apps, night light schedule, bar resources, tray filters, scrolling, pomodoro timings, AI models and the rest. Lists are edited as text, and the AI model list as JSON that only saves while valid.",
      },
      {
        title: "Search across every page",
        text: "370 labels are indexed. Results show where each option lives and take you to the exact row.",
      },
      {
        title: "Sections in the navigation rail",
        text: "The selected tab lists its sections. Click one to scroll there; the marker follows as you scroll.",
      },
      {
        title: "Tabs ordered by use",
        text: "Quick, Bar, Interface, Background, General, Services, Advanced, then Misc and About. Options that nothing in the shell reads are moved to Misc.",
      },
      {
        title: "Calmer rows",
        text: "Sections are grouped on cards, per-row icons are gone, units moved out of the labels, and short text values no longer take a full-width box.",
      },
      {
        title: "Update check and update button",
        text: "About reports how many commits your dotfiles are behind and how many system packages are pending. From there, one button opens a terminal running end-4's updater and re-applies this mod afterwards.",
      },
    ],
    footnote:
      'It also corrects one stock bug: the "force notifications to one monitor" switch wrote to a config key the shell did not define.',
  },
];

export const findProduct = (slug) => products.find((product) => product.slug === slug);
