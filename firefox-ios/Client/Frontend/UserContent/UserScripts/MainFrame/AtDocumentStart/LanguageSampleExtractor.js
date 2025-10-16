/// Maximum number of characters to include in the sample.
const MAX_LANGUAGE_SAMPLE_CHARS = 2000;

/// Extracts a sample of text from the current page to help with language detection.
/// Extracts `maxChars` characters from the middle of the page text.
/// Collapses whitespace and trims to a maximum character length.
/// NOTE: We can use reader mode content in the future, but that seems overkill for now.
const getLanguageSample = (maxChars = 2000) => {
  const text = (document.body?.innerText || document.documentElement?.innerText || "")
    .replace(/\s+/g, " ")
    .trim();
  
  if (!text) return "";
  // TODO(Issam): This unreadable. Also do we need to clean up text more?
  const start = Math.max(0, Math.floor(text.length / 2) - Math.floor(maxChars / 2));
  return text.slice(start, start + maxChars).trim();
};

/// Helper function to wait for document to be ready before running checks.
/// Returns a Promise that resolves when the document is ready.
const documentReady = () =>  new Promise(resolve => {
  if (document.readyState !== "loading") {
    resolve();
  } else {
    document.addEventListener("readystatechange", () => {
      if (document.readyState !== "loading") {
        resolve();
      }
    }, { once: true });
  }
});

/// Exposed helper to get a language sample after the document is ready.
export const getLanguageSampleWhenReady = async () => {
  await documentReady();
  return getLanguageSample();
};