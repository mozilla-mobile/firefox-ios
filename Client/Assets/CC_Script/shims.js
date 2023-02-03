HTMLSelectElement.isInstance = (element) =>
  element instanceof HTMLSelectElement;

HTMLInputElement.isInstance = (element) => element instanceof HTMLInputElement;

window.Cu = {
  getWeakReference: (elements) => ({
    get: () => elements,
  }),
};

HTMLElement.prototype.getAutocompleteInfo = function () {
  return {
    _reason: "autocomplete",
    fieldName: this.getAttribute("autocomplete") ?? "",
  };
};
