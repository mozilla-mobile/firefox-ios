import { enable as enableDarkReader, setFetchMethod } from "darkreader";

// Needed in order for dark reader to handle CORS properly
// This tells dark reader to use the global window.fetch.
setFetchMethod(window.fetch);

const THEME_CLASSES = ["light", "dark", "sepia"];
const FONT_TYPES = {
  "sans-serif": "-apple-system, sans-serif",
  serif: "new-york",
};
const DEFAULT_DR_CONFIGS = {
  light: {
    mode: 0,
    brightness: 100,
    contrast: 100,
    sepia: 0,
    lightSchemeBackgroundColor: "#ffffff",
    lightSchemeTextColor: "#15141a",
  },
  dark: {
    mode: 1,
    brightness: 100,
    contrast: 100,
    sepia: 0,
  },
  sepia: {
    mode: 0,
    brightness: 100,
    contrast: 100,
    sepia: 20,
    lightSchemeBackgroundColor: "#fff4de",
    lightSchemeTextColor: "#15141a",
  },
};

const applyFontConfig = (style) => {
  // Font Sizes (1–13)
  for (let i = 1; i <= 13; i++) {
    document.body.classList.toggle(`font-size${i}`, style?.fontSize === i);
  }

  document.body.classList.toggle("bold", style?.fontWeight === "bold");
  return {
    ...DEFAULT_DR_CONFIGS[style?.theme],
    useFont: true,
    fontFamily: FONT_TYPES[style?.fontType],
  };
};

export const setStyle = (style) => {
  // Remove all theme classes
  THEME_CLASSES.forEach((theme) => {
    document.body.classList.toggle(theme, theme === style?.theme);
  });
  // Apply new dark reader config with font setup
  const config = applyFontConfig(style);
  enableDarkReader(config);
};
