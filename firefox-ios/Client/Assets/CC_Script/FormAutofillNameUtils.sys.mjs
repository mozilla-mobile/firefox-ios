/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// FormAutofillNameUtils is initially translated from
// https://cs.chromium.org/chromium/src/components/autofill/core/browser/autofill_data_util.cc?rcl=b861deff77abecff11ae6a9f6946e9cc844b9817
export var FormAutofillNameUtils = {
  NAME_PREFIXES: [
    "1lt",
    "1st",
    "2lt",
    "2nd",
    "3rd",
    "admiral",
    "capt",
    "captain",
    "col",
    "cpt",
    "dr",
    "gen",
    "general",
    "lcdr",
    "lt",
    "ltc",
    "ltg",
    "ltjg",
    "maj",
    "major",
    "mg",
    "mr",
    "mrs",
    "ms",
    "pastor",
    "prof",
    "rep",
    "reverend",
    "rev",
    "sen",
    "st",
  ],

  NAME_SUFFIXES: [
    "b.a",
    "ba",
    "d.d.s",
    "dds",
    "i",
    "ii",
    "iii",
    "iv",
    "ix",
    "jr",
    "m.a",
    "m.d",
    "ma",
    "md",
    "ms",
    "ph.d",
    "phd",
    "sr",
    "v",
    "vi",
    "vii",
    "viii",
    "x",
  ],

  FAMILY_NAME_PREFIXES: [
    "d'",
    "de",
    "del",
    "der",
    "di",
    "la",
    "le",
    "mc",
    "san",
    "st",
    "ter",
    "van",
    "von",
  ],

  // The common and non-ambiguous CJK surnames (last names) that have more than
  // one character.
  COMMON_CJK_MULTI_CHAR_SURNAMES: [
    // Korean, taken from the list of surnames:
    // https://ko.wikipedia.org/wiki/%ED%95%9C%EA%B5%AD%EC%9D%98_%EC%84%B1%EC%94%A8_%EB%AA%A9%EB%A1%9D
    "남궁",
    "사공",
    "서문",
    "선우",
    "제갈",
    "황보",
    "독고",
    "망절",

    // Chinese, taken from the top 10 Chinese 2-character surnames:
    // https://zh.wikipedia.org/wiki/%E8%A4%87%E5%A7%93#.E5.B8.B8.E8.A6.8B.E7.9A.84.E8.A4.87.E5.A7.93
    // Simplified Chinese (mostly mainland China)
    "欧阳",
    "令狐",
    "皇甫",
    "上官",
    "司徒",
    "诸葛",
    "司马",
    "宇文",
    "呼延",
    "端木",
    // Traditional Chinese (mostly Taiwan)
    "張簡",
    "歐陽",
    "諸葛",
    "申屠",
    "尉遲",
    "司馬",
    "軒轅",
    "夏侯",
  ],

  // All Korean surnames that have more than one character, even the
  // rare/ambiguous ones.
  KOREAN_MULTI_CHAR_SURNAMES: [
    "강전",
    "남궁",
    "독고",
    "동방",
    "망절",
    "사공",
    "서문",
    "선우",
    "소봉",
    "어금",
    "장곡",
    "제갈",
    "황목",
    "황보",
  ],

  // The whitespace definition based on
  // https://cs.chromium.org/chromium/src/base/strings/string_util_constants.cc?l=9&rcl=b861deff77abecff11ae6a9f6946e9cc844b9817
  WHITESPACE: [
    "\u0009", // CHARACTER TABULATION
    "\u000A", // LINE FEED (LF)
    "\u000B", // LINE TABULATION
    "\u000C", // FORM FEED (FF)
    "\u000D", // CARRIAGE RETURN (CR)
    "\u0020", // SPACE
    "\u0085", // NEXT LINE (NEL)
    "\u00A0", // NO-BREAK SPACE
    "\u1680", // OGHAM SPACE MARK
    "\u2000", // EN QUAD
    "\u2001", // EM QUAD
    "\u2002", // EN SPACE
    "\u2003", // EM SPACE
    "\u2004", // THREE-PER-EM SPACE
    "\u2005", // FOUR-PER-EM SPACE
    "\u2006", // SIX-PER-EM SPACE
    "\u2007", // FIGURE SPACE
    "\u2008", // PUNCTUATION SPACE
    "\u2009", // THIN SPACE
    "\u200A", // HAIR SPACE
    "\u2028", // LINE SEPARATOR
    "\u2029", // PARAGRAPH SEPARATOR
    "\u202F", // NARROW NO-BREAK SPACE
    "\u205F", // MEDIUM MATHEMATICAL SPACE
    "\u3000", // IDEOGRAPHIC SPACE
  ],

  // The middle dot is used as a separator for foreign names in Japanese.
  MIDDLE_DOT: [
    "\u30FB", // KATAKANA MIDDLE DOT
    "\u00B7", // A (common?) typo for "KATAKANA MIDDLE DOT"
  ],

  // The Unicode range is based on Wiki:
  // https://en.wikipedia.org/wiki/CJK_Unified_Ideographs
  // https://en.wikipedia.org/wiki/Hangul
  // https://en.wikipedia.org/wiki/Japanese_writing_system
  CJK_RANGE: [
    "\u1100-\u11FF", // Hangul Jamo
    "\u3040-\u309F", // Hiragana
    "\u30A0-\u30FF", // Katakana
    "\u3105-\u312C", // Bopomofo
    "\u3130-\u318F", // Hangul Compatibility Jamo
    "\u31F0-\u31FF", // Katakana Phonetic Extensions
    "\u3200-\u32FF", // Enclosed CJK Letters and Months
    "\u3400-\u4DBF", // CJK unified ideographs Extension A
    "\u4E00-\u9FFF", // CJK Unified Ideographs
    "\uA960-\uA97F", // Hangul Jamo Extended-A
    "\uAC00-\uD7AF", // Hangul Syllables
    "\uD7B0-\uD7FF", // Hangul Jamo Extended-B
    "\uFF00-\uFFEF", // Halfwidth and Fullwidth Forms
  ],

  HANGUL_RANGE: [
    "\u1100-\u11FF", // Hangul Jamo
    "\u3130-\u318F", // Hangul Compatibility Jamo
    "\uA960-\uA97F", // Hangul Jamo Extended-A
    "\uAC00-\uD7AF", // Hangul Syllables
    "\uD7B0-\uD7FF", // Hangul Jamo Extended-B
  ],

  _dataLoaded: false,

  // Returns true if |set| contains |token|, modulo a final period.
  _containsString(set, token) {
    let target = token.replace(/\.$/, "").toLowerCase();
    return set.includes(target);
  },

  // Removes common name prefixes from |name_tokens|.
  _stripPrefixes(nameTokens) {
    for (let i in nameTokens) {
      if (!this._containsString(this.NAME_PREFIXES, nameTokens[i])) {
        return nameTokens.slice(i);
      }
    }
    return [];
  },

  // Removes common name suffixes from |name_tokens|.
  _stripSuffixes(nameTokens) {
    for (let i = nameTokens.length - 1; i >= 0; i--) {
      if (!this._containsString(this.NAME_SUFFIXES, nameTokens[i])) {
        return nameTokens.slice(0, i + 1);
      }
    }
    return [];
  },

  _isCJKName(name) {
    // The name is considered to be a CJK name if it is only CJK characters,
    // spaces, and "middle dot" separators, with at least one CJK character, and
    // no more than 2 words.
    //
    // Chinese and Japanese names are usually spelled out using the Han
    // characters (logographs), which constitute the "CJK Unified Ideographs"
    // block in Unicode, also referred to as Unihan. Korean names are usually
    // spelled out in the Korean alphabet (Hangul), although they do have a Han
    // equivalent as well.

    if (!name) {
      return false;
    }

    let previousWasCJK = false;
    let wordCount = 0;

    for (let c of name) {
      let isMiddleDot = this.MIDDLE_DOT.includes(c);
      let isCJK = !isMiddleDot && this.reCJK.test(c);
      if (!isCJK && !isMiddleDot && !this.WHITESPACE.includes(c)) {
        return false;
      }
      if (isCJK && !previousWasCJK) {
        wordCount++;
      }
      previousWasCJK = isCJK;
    }

    return wordCount > 0 && wordCount < 3;
  },

  // Tries to split a Chinese, Japanese, or Korean name into its given name &
  // surname parts. If splitting did not work for whatever reason, returns null.
  _splitCJKName(nameTokens) {
    // The convention for CJK languages is to put the surname (last name) first,
    // and the given name (first name) second. In a continuous text, there is
    // normally no space between the two parts of the name. When entering their
    // name into a field, though, some people add a space to disambiguate. CJK
    // names (almost) never have a middle name.

    let reHangulName = new RegExp(
      "^[" + this.HANGUL_RANGE.join("") + this.WHITESPACE.join("") + "]+$",
      "u"
    );
    let nameParts = {
      given: "",
      middle: "",
      family: "",
    };

    if (nameTokens.length == 1) {
      // There is no space between the surname and given name. Try to infer
      // where to separate between the two. Most Chinese and Korean surnames
      // have only one character, but there are a few that have 2. If the name
      // does not start with a surname from a known list, default to one
      // character.
      let name = nameTokens[0];
      let isKorean = reHangulName.test(name);
      let surnameLength = 0;

      // 4-character Korean names are more likely to be 2/2 than 1/3, so use
      // the full list of Korean 2-char surnames. (instead of only the common
      // ones)
      let multiCharSurnames =
        isKorean && name.length > 3
          ? this.KOREAN_MULTI_CHAR_SURNAMES
          : this.COMMON_CJK_MULTI_CHAR_SURNAMES;

      // Default to 1 character if the surname is not in the list.
      surnameLength = multiCharSurnames.some(surname =>
        name.startsWith(surname)
      )
        ? 2
        : 1;

      nameParts.family = name.substr(0, surnameLength);
      nameParts.given = name.substr(surnameLength);
    } else if (nameTokens.length == 2) {
      // The user entered a space between the two name parts. This makes our job
      // easier. Family name first, given name second.
      nameParts.family = nameTokens[0];
      nameParts.given = nameTokens[1];
    } else {
      return null;
    }

    return nameParts;
  },

  init() {
    if (this._dataLoaded) {
      return;
    }
    this._dataLoaded = true;

    this.reCJK = new RegExp("[" + this.CJK_RANGE.join("") + "]", "u");
  },

  splitName(name) {
    let nameParts = {
      given: "",
      middle: "",
      family: "",
    };

    if (!name) {
      return nameParts;
    }

    let nameTokens = name.trim().split(/[ ,\u3000\u30FB\u00B7]+/);
    nameTokens = this._stripPrefixes(nameTokens);

    if (this._isCJKName(name)) {
      let parts = this._splitCJKName(nameTokens);
      if (parts) {
        return parts;
      }
    }

    // Don't assume "Ma" is a suffix in John Ma.
    if (nameTokens.length > 2) {
      nameTokens = this._stripSuffixes(nameTokens);
    }

    if (!nameTokens.length) {
      // Bad things have happened; just assume the whole thing is a given name.
      nameParts.given = name;
      return nameParts;
    }

    // Only one token, assume given name.
    if (nameTokens.length == 1) {
      nameParts.given = nameTokens[0];
      return nameParts;
    }

    // 2 or more tokens. Grab the family, which is the last word plus any
    // recognizable family prefixes.
    let familyTokens = [nameTokens.pop()];
    while (nameTokens.length) {
      let lastToken = nameTokens[nameTokens.length - 1];
      if (!this._containsString(this.FAMILY_NAME_PREFIXES, lastToken)) {
        break;
      }
      familyTokens.unshift(lastToken);
      nameTokens.pop();
    }
    nameParts.family = familyTokens.join(" ");

    // Take the last remaining token as the middle name (if there are at least 2
    // tokens).
    if (nameTokens.length >= 2) {
      nameParts.middle = nameTokens.pop();
    }

    // Remainder is given name.
    nameParts.given = nameTokens.join(" ");

    return nameParts;
  },

  joinNameParts({ given, middle, family }) {
    if (this._isCJKName(given) && this._isCJKName(family) && !middle) {
      return family + given;
    }
    return [given, middle, family]
      .filter(part => part && part.length)
      .join(" ");
  },
};

FormAutofillNameUtils.init();
