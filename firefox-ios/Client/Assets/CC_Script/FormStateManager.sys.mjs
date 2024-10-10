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
   * Get the form handler for the specified input element.
   *
   * @param {HTMLInputElement} element
   *        Focused input which triggered profile searching
   * @returns {FormAutofillHandler | null}
   *        The form handler associated with the specified input element.
   */
  getFormHandler(element) {
    if (!element) {
      return null;
    }

    const rootElement = lazy.AutofillFormFactory.findRootForField(element);
    return this._formsDetails.get(rootElement);
  }

  /**
   * Get the form handler for the specified input element. If no handler exists
   * in the cache, this function creates a new one.
   *
   * @param {HTMLInputElement} element
   *        Focused input which triggered profile searching
   * @returns {FormAutofillHandler}
   *        The form handler associated with the specified input element.
   */
  getOrCreateFormHandler(element) {
    let handler = this.getFormHandler(element);
    if (!handler) {
      handler = new lazy.FormAutofillHandler(
        lazy.AutofillFormFactory.createFromField(element),
        this.onFilledModifiedCallback
      );
      this._formsDetails.set(handler.form.rootElement, handler);
    }
    return handler;
  }
}

export default FormStateManager;
