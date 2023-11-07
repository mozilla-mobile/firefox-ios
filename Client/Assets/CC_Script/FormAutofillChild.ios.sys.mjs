/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* eslint-disable no-undef,mozilla/balanced-listeners */
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { FormStateManager } from "resource://gre/modules/shared/FormStateManager.sys.mjs";
import { CreditCardRecord } from "resource://gre/modules/shared/CreditCardRecord.sys.mjs";

export class FormAutofillChild {
  /**
   * Creates an instance of FormAutofillChild.
   *
   * @param {object} callbacks - An object containing callback functions.
   * @param {object} callbacks.address - Callbacks related to addresses.
   * @param {Function} callbacks.address.autofill - Function called to autofill address fields.
   * @param {Function} callbacks.address.submit - Function called on address form submission.
   * @param {object} callbacks.creditCard - Callbacks related to credit cards.
   * @param {Function} callbacks.creditCard.autofill - Function called to autofill credit card fields.
   * @param {Function} callbacks.creditCard.submit - Function called on credit card form submission.
   */
  constructor(callbacks) {
    this.onFocusIn = this.onFocusIn.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.callbacks = callbacks;

    this.fieldDetailsManager = new FormStateManager();

    document.addEventListener("focusin", this.onFocusIn);
    document.addEventListener("submit", this.onSubmit);
  }

  _doIdentifyAutofillFields(element) {
    this.fieldDetailsManager.updateActiveInput(element);
    const validDetails =
      this.fieldDetailsManager.identifyAutofillFields(element);

    const activeFieldName =
      this.fieldDetailsManager.activeFieldDetail?.fieldName;

    // Only ping swift if current field is either a cc or address field
    if (!validDetails?.find(field => field.element === element)) {
      return;
    }

    const fieldNamesWithValues =
      this.transformToFieldNamesWithValues(validDetails);

    if (FormAutofillUtils.isAddressField(activeFieldName)) {
      this.callbacks.address.autofill(fieldNamesWithValues);
    } else if (FormAutofillUtils.isCreditCardField(activeFieldName)) {
      // Normalize record format so we always get a consistent
      // credit card record format: {cc-number, cc-name, cc-exp-month, cc-exp-year}
      CreditCardRecord.normalizeFields(fieldNamesWithValues);
      this.callbacks.creditCard.autofill(fieldNamesWithValues);
    }
  }

  transformToFieldNamesWithValues(details) {
    return details?.reduce(
      (acc, field) => ({
        ...acc,
        [field.fieldName]: field.element.value,
      }),
      {}
    );
  }

  onFocusIn(evt) {
    const element = evt.target;
    this.fieldDetailsManager.updateActiveInput(element);
    if (!FormAutofillUtils.isCreditCardOrAddressFieldType(element)) {
      return;
    }
    this._doIdentifyAutofillFields(element);
  }

  onSubmit(evt) {
    this.fieldDetailsManager.activeHandler.onFormSubmitted();
    const records = this.fieldDetailsManager.activeHandler.createRecords();
    if (records.creditCard) {
      // Normalize record format so we always get a consistent
      // credit card record format: {cc-number, cc-name, cc-exp-month, cc-exp-year}
      const creditCardRecords = records.creditCard.map(entry => {
        CreditCardRecord.normalizeFields(entry.record);
        return entry.record;
      });
      this.callbacks.creditCard.submit(creditCardRecords);
    }

    // TODO(FXSP-133 Phase 3): Support address capture
    // this.callbacks.address.submit();
  }

  fillFormFields(payload) {
    this.fieldDetailsManager.activeHandler.autofillFormFields(payload);
  }
}

export default FormAutofillChild;
