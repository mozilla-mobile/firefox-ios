HTMLSelectElement.isInstance = (element) =>
  element instanceof HTMLSelectElement;

HTMLInputElement.isInstance = (element) => element instanceof HTMLInputElement;

window.Cu = class {
  static getWeakReference(elements) {
    const elementsWeakRef = new WeakRef(elements);
    return {
      get: () => elementsWeakRef.deref(),
    };
  }
};

HTMLFormElement.prototype.addEventListener = function () {
  const submitEventListeners = this.getEventListeners("submit");
  console.log("submitEventListeners", submitEventListeners);
};

HTMLElement.prototype.getAutocompleteInfo = function () {
  // TODO: Hack for PoC only
  // Need to find a better way to get the autocomplete field name
  // Reference: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
  const validAutocompleteFields = [
    "off",
    "on",
    "name",
    "honorific-prefix",
    "given-name",
    "additional-name",
    "family-name",
    "honorific-suffix",
    "nickname",
    "email",
    "username",
    "new-password",
    "current-password",
    "one-time-code",
    "organization-title",
    "organization",
    "street-address",
    "address-line1",
    "address-line2",
    "address-line3",
    "address-level4",
    "address-level3",
    "address-level2",
    "address-level1",
    "country",
    "country-name",
    "postal-code",
    "cc-name",
    "cc-given-name",
    "cc-additional-name",
    "cc-family-name",
    "cc-number",
    "cc-exp",
    "cc-exp-month",
    "cc-exp-year",
    "cc-csc",
    "cc-type",
    "transaction-currency",
    "transaction-amount",
    "language",
    "bday",
    "bday-day",
    "bday-month",
    "bday-year",
    "sex",
    "tel",
    "tel-country-code",
    "tel-national",
    "tel-area-code",
    "tel-local",
    "tel-extension",
    "impp",
    "url",
    "photo",
  ];
  return {
    _reason: "autocomplete",
    fieldName:
      this.getAttribute("autocomplete") in validAutocompleteFields
        ? this.getAttribute("autocomplete")
        : "",
  };
};
