// The catalog. Sizes and file counts come from build_site.py (settings-rework.generated.json),
// so they always describe the zip that is actually in public/downloads.
import settingsRework from "./settings-rework.generated.json";
import login from "./login.generated.json";

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
    ...settingsRework,
    fourthFact: { value: "0", label: "New dependencies" },
    installSteps: [
      {
        title: "Unzip and run the installer",
        command: "cd ~/Downloads\nunzip ii-settings-rework.zip\nbash ii-settings-rework/install.sh",
        text: "It backs up every file it replaces to `~/.local/share/ii-settings-rework/backup`, then copies the new ones into `~/.config/quickshell/ii`. No root, no packages.",
      },
      {
        title: "Reopen Settings",
        text: "Close the settings window if it is open and launch it again. The shell itself does not need a restart.",
      },
    ],
    notes: [
      {
        title: "Built against",
        text: `dots-hyprland commit \`${settingsRework.commit}\` (${settingsRework.commitDate}). If your settings files differ from that version the installer stops and tells you which; \`--force\` installs anyway.`,
      },
      {
        title: "Uninstall",
        command: "bash ii-settings-rework/install.sh --uninstall",
        text: "Restores the backup and removes the added files.",
      },
      {
        title: "After a dots update",
        text: "Updating the dotfiles replaces these files with stock ones. The Update dotfiles button in About re-applies the mod for you; after a manual update, run the installer again.",
      },
    ],
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
        id: "displays",
        label: "Displays",
        src: asset("shots/displays.png"),
        caption:
          "The Displays page. Drag the numbered tiles to arrange your monitors, then set each one's resolution, refresh rate, scale and rotation. Apply asks you to keep the result and undoes it otherwise.",
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
        title: "Displays page",
        text: "Drag your monitors into place and set resolution, refresh rate, scale and rotation, with the result written to Hyprland's monitors.lua. New settings are undone after 15 seconds unless you keep them, so a mode your screen cannot show never leaves you stuck.",
      },
      {
        title: "Update check and update button",
        text: "About reports how many commits your dotfiles are behind and how many system packages are pending. From there, one button opens a terminal running end-4's updater and re-applies this mod afterwards.",
      },
    ],
    footnote:
      'It also corrects one stock bug: the "force notifications to one monitor" switch wrote to a config key the shell did not define.',
  },
  {
    slug: "login",
    name: "ii Login",
    target: "SDDM login screen",
    tagline: "The login screen that matches your lockscreen.",
    summary:
      "An SDDM theme that reproduces the illogical-impulse lockscreen: the same clock, toolbars, colours and blurred wallpaper, kept in step with your desktop.",
    description: [
      "The screen you see at boot is SDDM, not the Quickshell lockscreen, so it looks nothing like the rest of the desktop.",
      "This theme rebuilds the lockscreen for SDDM and follows your wallpaper and colours as they change. SDDM still checks your password; the theme only draws the screen.",
    ],
    download: asset("downloads/ii-login.zip"),
    downloadName: "ii-login.zip",
    folder: "ii-login",
    ...login,
    fourthFact: { value: "1", label: "Sudo prompt, at install" },
    cover: asset("shots/login-main.png"),
    screenshots: [
      {
        id: "login-main",
        label: "Login screen",
        src: asset("shots/login-main.png"),
        caption:
          "The analog clock, quote and date in the middle; user, password and session along the bottom. Colours and the blurred wallpaper come from the desktop.",
      },
      {
        id: "login-typing",
        label: "Typing",
        src: asset("shots/login-typing.png"),
        caption: "Password characters appear as a cycle of seven shapes, as they do on the lockscreen.",
      },
      {
        id: "login-wrong",
        label: "Wrong password",
        src: asset("shots/login-wrong.png"),
        caption: "A wrong password clears the field, shakes it and says so.",
      },
      {
        id: "login-session",
        label: "Session menu",
        src: asset("shots/login-session.png"),
        caption: "The session picker lists what is installed and remembers the last one used.",
      },
    ],
    changes: [
      {
        title: "Same layout as the lockscreen",
        text: "Three pill toolbars along the bottom: user and keyboard layout, the password field, and session, sleep, power off and restart.",
      },
      {
        title: "Follows your wallpaper and colours",
        text: "A small user service re-syncs the theme whenever the shell regenerates its colours or you change its options. The blur is baked into the image, so the login screen needs no shaders.",
      },
      {
        title: "The cookie clock",
        text: "The analog clock with its scalloped face, date bubbles and your quote. Where the lockscreen says Locked, the login screen shows the date.",
      },
      {
        title: "More than one monitor",
        text: "The primary monitor gets the full login controls; the others show the wallpaper, the clock and a password field of their own, so what you type shows on whichever monitor the pointer is on. An install option rotates a portrait monitor that SDDM would otherwise show sideways.",
      },
      {
        title: "Session picker and caps lock",
        text: "Two things a login screen needs that a lockscreen does not: a menu of installed sessions, and a warning when caps lock is on.",
      },
      {
        title: "Theme code stays root-owned",
        text: "Only colours, fonts, text and one image are writable by your user. If the theme ever fails to load, SDDM falls back to its built-in login screen.",
      },
    ],
    installSteps: [
      {
        title: "Unzip and run the installer",
        command: "cd ~/Downloads\nunzip ii-login.zip\nbash ii-login/install.sh",
        text: "Run it as yourself; it asks for your sudo password once. It copies the theme to `/usr/share/sddm/themes/ii-login`, selects it in `/etc/sddm.conf.d/10-ii-login.conf`, and enables the sync service for your user. Needs SDDM, ImageMagick and Python, which an end-4 install already has.",
      },
      {
        title: "Reboot",
        text: "The new login screen appears at the next boot. Your current session is not touched.",
      },
    ],
    notes: [
      {
        title: "Portrait monitor",
        command: "bash ii-login/install.sh --rotate left",
        text: "For a main monitor on DisplayPort and a rotated one on HDMI. If it comes up upside down, run it again with `--rotate right`. This also needs `xrandr`.",
      },
      {
        title: "If the login screen misbehaves",
        command: "sudo rm /etc/sddm.conf.d/10-ii-login.conf && sudo systemctl restart sddm",
        text: "Press Ctrl+Alt+F3, log in on the text console and run this to get the previous login screen back.",
      },
      {
        title: "Uninstall",
        command: "bash ii-login/install.sh --uninstall",
        text: "Removes the theme, its data folder, the config file and the sync service.",
      },
      {
        title: "What it reproduces",
        text: `Built from dots-hyprland commit \`${login.commit}\` (${login.commitDate}). It reproduces the cookie clock; if you set the locked clock to the digital style, the login screen will not follow.`,
      },
    ],
    footnote:
      "Power off, restart and sleep work from the login screen without a password, as they do on SDDM's default screen. Your blurred wallpaper and quote are visible before login.",
  },
];

export const findProduct = (slug) => products.find((product) => product.slug === slug);
