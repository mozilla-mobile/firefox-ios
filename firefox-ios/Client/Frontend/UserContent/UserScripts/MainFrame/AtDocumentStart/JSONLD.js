/**
 * Finds the first JSON-LD node of a given @type on the page.
 * - Scans all <script type="application/ld+json">
 * - Parses JSON safely (ignores broken blocks).
 * - Unwraps @graph arrays so nested items are discoverable.
 * @param {string} ofType - The target schema.org @type (e.g., "Recipe").
 * @returns {object|null}
 */
const findJSONLD = (ofType) => {
  const nodes = document.querySelectorAll(`script[type="application/ld+json" i]`);
  const parsed = [];
  
  for (const node of nodes) {
    try {
      const obj = JSON.parse(node.textContent.trim());
      parsed.push(...(Array.isArray(obj) ? obj : [obj]));
    } catch {
      // Silently skip malformed JSON-LD blocks
    }
  }
  
  const all = parsed.flatMap(o => Array.isArray(o["@graph"]) ? o["@graph"] : [o]);
  
  const isType = o => {
    const t = o?.["@type"];
    return t === ofType || (Array.isArray(t) && t.includes(ofType));
  };
  
  return all.find(isType) || null;
}

/**
 * Remove specific top-level fields from a JSON-LD object.
 * Shallow only — nested objects/arrays are not traversed.
 * @param {object|null} json
 * @param {string[]} fields
 * @returns {object|null}
 */
const stripJSONLDFields = (json, fields = []) =>{
  if (!json) return null;
  return Object.fromEntries(
    Object.entries(json).filter(([key]) => !fields.includes(key))
  );
}

/**
 * Find and return a cleaned Recipe object from the current page.
 * @returns {object|null}
 * For more context on the schema, see https://schema.org/Recipe
 */
export const findRecipeJSONLD = () => {
  const recipe = findJSONLD("Recipe");
  if (!recipe) return null;
  return stripJSONLDFields(recipe, ["name", "dateCreated", "dateModified", "datePublished", "review"])
}