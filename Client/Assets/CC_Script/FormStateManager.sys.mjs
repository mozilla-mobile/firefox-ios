/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofillHandler } from "resource://gre/modules/shared/FormAutofillHandler.sys.mjs";
import { FormLikeFactory } from "resource://gre/modules/FormLikeFactory.sys.mjs";

export class FormStateManager {
  constructor(onSubmit, onAutofillCallback) {
    /**
     * @type {WeakMap} mapping FormLike root HTML elements to FormAutofillHandler objects.
     */
    this._formsDetails = new WeakMap();
    /**
     * @type {object} The object where to store the active items, e.g. element,
     * handler, section, and field detail.
     */
    this._activeItems = {};

    this.onSubmit = onSubmit;

    this.onAutofillCallback = onAutofillCallback;
  }

  /**
   * Get the active input's information from cache which is created after page
   * identified.
   *
   * @returns {object | null}
   *          Return the active input's information that cloned from content cache
   *          (or return null if the information is not found in the cache).
   */
  get activeFieldDetail() {
    if (!this._activeItems.fieldDetail) {
      let formDetails = this.activeFormDetails;
      if (!formDetails) {
        return null;
      }
      for (let detail of formDetails) {
        let detailElement = detail.elementWeakRef.get();
        if (detailElement && this.activeInput == detailElement) {
          this._activeItems.fieldDetail = detail;
          break;
        }
      }
    }
    return this._activeItems.fieldDetail;
  }

  /**
   * Get the active form's information from cache which is created after page
   * identified.
   *
   * @returns {Array<object> | null}
   *          Return target form's information from content cache
   *          (or return null if the information is not found in the cache).
   *
   */
  get activeFormDetails() {
    let formHandler = this.activeHandler;
    return formHandler ? formHandler.fieldDetails : null;
  }

  get activeInput() {
    let elementWeakRef = this._activeItems.elementWeakRef;
    return elementWeakRef ? elementWeakRef.get() : null;
  }

  get activeHandler() {
    const activeInput = this.activeInput;
    if (!activeInput) {
      return null;
    }

    // XXX: We are recomputing the activeHandler every time to avoid keeping a
    // reference on the active element. This might be called quite frequently
    // so if _getFormHandler/findRootForField become more costly, we should
    // look into caching this result (eg by adding a weakmap).
    let handler = this._getFormHandler(activeInput);
    if (handler) {
      handler.focusedInput = activeInput;
    }
    return handler;
  }

  get activeSection() {
    let formHandler = this.activeHandler;
    return formHandler ? formHandler.activeSection : null;
  }

  /**
   * Get the form's handler from cache which is created after page identified.
   *
   * @param {HTMLInputElement} element Focused input which triggered profile searching
   * @returns {Array<object> | null}
   *          Return target form's handler from content cache
   *          (or return null if the information is not found in the cache).
   *
   */
  _getFormHandler(element) {
    if (!element) {
      return null;
    }
    let rootElement = FormLikeFactory.findRootForField(element);
    return this._formsDetails.get(rootElement);
  }

  identifyAutofillFields(element) {
    let formHandler = this._getFormHandler(element);
    if (!formHandler) {
      let formLike = FormLikeFactory.createFromField(element);
      formHandler = new FormAutofillHandler(
        formLike,
        this.onSubmit,
        this.onAutofillCallback
      );
    } else if (!formHandler.updateFormIfNeeded(element)) {
      return formHandler.fieldDetails;
    }
    this._formsDetails.set(formHandler.form.rootElement, formHandler);
    return formHandler.collectFormFields();
  }

  updateActiveInput(element) {
    if (!element) {
      this._activeItems = {};
      return;
    }
    this._activeItems = {
      elementWeakRef: Cu.getWeakReference(element),
      fieldDetail: null,
    };
  }

  getRecords(formElement, handler) {
    handler = handler || this._formsDetails.get(formElement);
    const records = handler?.createRecords();

    if (
      !handler ||
      !records ||
      !Object.values(records).some(typeRecords => typeRecords.length)
    ) {
      return null;
    }
    return records;
  }
}

export default FormStateManager;
