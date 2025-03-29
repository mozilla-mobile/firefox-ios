/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  AutofillFormFactory:
    "resource://gre/modules/shared/AutofillFormFactory.sys.mjs",
  FormAutofillHandler:
    "resource://gre/modules/shared/FormAutofillHandler.sys.mjs",
  FormAutofillUtils: "resource://gre/modules/shared/FormAutofillUtils.sys.mjs",
});

export class FormStateManager {
  #formHandlerByElement = new WeakMap();
  #formHandlerByRootElement = new WeakMap();
  #formHandlerByRootId = new Map();

  constructor(onFilledModifiedCallback) {
    /**
     * @type {WeakMap} mapping FormLike root HTML elements to FormAutofillHandler objects.
     */

    this.onFilledModifiedCallback = onFilledModifiedCallback;
  }

  getWeakIdentifiedForms() {
    return ChromeUtils.nondeterministicGetWeakMapKeys(
      this.#formHandlerByRootElement
    );
  }

  /**
   * Get the form handler for the specified input element.
   *
   * @param {HTMLElement} element
   *        Focused input which triggered profile searching
   * @returns {FormAutofillHandler | null}
   *        The form handler associated with the specified input element.
   */
  getFormHandler(element) {
    if (!element) {
      return null;
    }

    let handler = this.#formHandlerByElement.get(element);
    if (handler) {
      return handler;
    }

    const rootElement = lazy.AutofillFormFactory.findRootForField(element);
    return this.#formHandlerByRootElement.get(rootElement);
  }

  /**
   * Get the form handler for the specified root element.
   *
   * @param {string} rootElementId
   *        the id of the root element
   * @returns {FormAutofillHandler | null}
   *        The form handler associated with the specified input element.
   */
  getFormHandlerByRootElementId(rootElementId) {
    return this.#formHandlerByRootId.get(rootElementId);
  }

  /**
   * Get the form handler for the specified input element. If no handler exists
   * in the cache, this function creates a new one.
   *
   * @param {HTMLElement} element
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

      const root = handler.form.rootElement;
      const rootElementId = lazy.FormAutofillUtils.getElementIdentifier(root);
      this.#formHandlerByRootId.set(rootElementId, handler);
      this.#formHandlerByRootElement.set(root, handler);
    }
    return handler;
  }

  removeFormHandlerByElementEntries(handler) {
    handler.form.elements.forEach(element =>
      this.#formHandlerByElement.delete(element)
    );
  }

  addFormHandlerByElementEntries(handler) {
    handler.form.elements.forEach(element => {
      if (!this.#formHandlerByElement.has(element, handler)) {
        this.#formHandlerByElement.set(element, handler);
      }
    });
  }
}

export default FormStateManager;
