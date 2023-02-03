export const FormAutofillUtilsShared = {
  FIELD_STATES: {
    NORMAL: "NORMAL",
    AUTO_FILLED: "AUTO_FILLED",
    PREVIEW: "PREVIEW",
  },
  FIELD_NAME_INFO: {
    name: "name",
    "given-name": "name",
    "additional-name": "name",
    "family-name": "name",
    organization: "organization",
    "street-address": "address",
    "address-line1": "address",
    "address-line2": "address",
    "address-line3": "address",
    "address-level1": "address",
    "address-level2": "address",
    "postal-code": "address",
    country: "address",
    "country-name": "address",
    tel: "tel",
    "tel-country-code": "tel",
    "tel-national": "tel",
    "tel-area-code": "tel",
    "tel-local": "tel",
    "tel-local-prefix": "tel",
    "tel-local-suffix": "tel",
    "tel-extension": "tel",
    email: "email",
    "cc-name": "creditCard",
    "cc-given-name": "creditCard",
    "cc-additional-name": "creditCard",
    "cc-family-name": "creditCard",
    "cc-number": "creditCard",
    "cc-exp-month": "creditCard",
    "cc-exp-year": "creditCard",
    "cc-exp": "creditCard",
    "cc-type": "creditCard",
  },

  ELIGIBLE_INPUT_TYPES: ["text", "email", "tel", "number", "month"],
  SECTION_TYPES: {
    ADDRESS: "address",
    CREDIT_CARD: "creditCard",
  },

  isAddressField(fieldName) {
    return (
      !!this.FIELD_NAME_INFO[fieldName] && !this.isCreditCardField(fieldName)
    );
  },

  isCreditCardField(fieldName) {
    return this.FIELD_NAME_INFO[fieldName] == "creditCard";
  },

  getCategoryFromFieldName(fieldName) {
    return this.FIELD_NAME_INFO[fieldName];
  },

  getCategoriesFromFieldNames(fieldNames) {
    let categories = new Set();
    for (let fieldName of fieldNames) {
      let info = this.getCategoryFromFieldName(fieldName);
      if (info) {
        categories.add(info);
      }
    }
    return Array.from(categories);
  },
  /**
   *  Determines if an element is visually hidden or not.
   *
   * NOTE: this does not encompass every possible way of hiding an element.
   * Instead, we check some of the more common methods of hiding for performance reasons.
   * See Bug 1727832 for follow up.
   *
   * @param {HTMLElement} element
   * @returns {boolean} true if the element is visible
   */
  isFieldVisible(element) {
    if (element.hidden) {
      return false;
    }
    if (element.style.display == "none") {
      return false;
    }
    return true;
  },

  /**
   * Determines if an element is eligible to be used by credit card or address autofill.
   *
   * @param {HTMLElement} element
   * @returns {boolean} true if element can be used by credit card or address autofill
   */
  isCreditCardOrAddressFieldType(element) {
    if (!element) {
      return false;
    }
    if (HTMLInputElement.isInstance(element)) {
      // `element.type` can be recognized as `text`, if it's missing or invalid.
      if (!this.ELIGIBLE_INPUT_TYPES.includes(element.type)) {
        return false;
      }
      // If the field is visually invisible, we do not want to autofill into it.
      if (!this.isFieldVisible(element)) {
        return false;
      }
    } else if (!HTMLSelectElement.isInstance(element)) {
      return false;
    }

    return true;
  },

  CC_FATHOM_NONE: 0,
  CC_FATHOM_JS: 1,
  CC_FATHOM_NATIVE: 2,
  isFathomCreditCardsEnabled(ccHeuristicsMode) {
    return ccHeuristicsMode != this.CC_FATHOM_NONE;
  },

  /**
   * Transform the key in FormAutofillConfidences (defined in ChromeUtils.webidl)
   * to fathom recognized field type.
   *
   * @param {string} key key from FormAutofillConfidences dictionary
   * @returns {string} fathom field type
   */
  formAutofillConfidencesKeyToCCFieldType(key) {
    const MAP = {
      ccNumber: "cc-number",
      ccName: "cc-name",
      ccType: "cc-type",
      ccExp: "cc-exp",
      ccExpMonth: "cc-exp-month",
      ccExpYear: "cc-exp-year",
    };
    return MAP[key];
  },
};
