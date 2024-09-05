/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  AutofillFormFactory:
    "resource://gre/modules/shared/AutofillFormFactory.sys.mjs",
  FormAutofillHandler:
    "resource://gre/modules/shared/FormAutofillHandler.sys.mjs",
});

export class FormStateManager {
  constructor(onFilledModifiedCallback) {
    /**
     * @type {WeakMap} mapping FormLike root HTML elements to FormAutofillHandler objects.
     */
    this._formsDetails = new WeakMap();

    this.onFilledModifiedCallback = onFilledModifiedCallback;
  }

  /**
   * Get the form's handler from cache which is created after page identified.
   *
   * @param {HTMLInputElement} element Focused input which triggered profile searching
   * @returns {Array<object> | null}
   *          Return target form's handler from content cache
   *          (or return null if the information is not found in the cache).
   */
  getFormHandler(element) {
    if (!element) {
      return null;
    }

    const rootElement = lazy.AutofillFormFactory.findRootForField(element);
    return this._formsDetails.get(rootElement);
  }

  /**
   * Identifies and handles autofill fields in a form element.
   *
   * This function retrieves a form handler for the given element and returns the
   * form handler. If the form handler already exists and the form does not change
   * since last time we identify its fields, it sets `newFieldsIdentifided` to false.
   *
   * @param {HTMLElement} element The form element to identify autofill fields for.
   * @returns {object} a {handler, newFieldsIdentified} object
   */
  identifyAutofillFields(element) {
    let handler = this.getFormHandler(element);
    if (handler && !handler.updateFormIfNeeded(element)) {
      return { handler, newFieldsIdentified: false };
    }

    if (!handler) {
      handler = new lazy.FormAutofillHandler(
        lazy.AutofillFormFactory.createFromField(element),
        this.onFilledModifiedCallback
      );
      this._formsDetails.set(handler.form.rootElement, handler);
    }

    handler.collectFormFields();
    return { handler, newFieldsIdentified: true };
  }
}

export default FormStateManager;
