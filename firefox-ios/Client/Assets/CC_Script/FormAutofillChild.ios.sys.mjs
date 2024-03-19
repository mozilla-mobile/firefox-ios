/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* eslint-disable no-undef,mozilla/balanced-listeners */
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { FormStateManager } from "resource://gre/modules/shared/FormStateManager.sys.mjs";
import { CreditCardRecord } from "resource://gre/modules/shared/CreditCardRecord.sys.mjs";
import { AddressRecord } from "resource://gre/modules/shared/AddressRecord.sys.mjs";

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
    this.fieldDetailsManager.identifyAutofillFields(element);

    const activeFieldName =
      this.fieldDetailsManager.activeFieldDetail?.fieldName;

    const activeFieldDetails =
      this.fieldDetailsManager.activeSection?.fieldDetails;

    // Only ping swift if current field is either a cc or address field
    if (!activeFieldDetails?.find(field => field.element === element)) {
      return;
    }

    const fieldNamesWithValues =
      this.transformToFieldNamesWithValues(activeFieldDetails);
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

  onSubmit(_event) {
    if (!this.fieldDetailsManager.activeHandler) {
      return;
    }

    this.fieldDetailsManager.activeHandler.onFormSubmitted();
    const records = this.fieldDetailsManager.activeHandler.createRecords();

    if (records.creditCard.length) {
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
    // In iOS, we have access only to valid fields (https://github.com/mozilla/application-services/blob/9054db4bb5031881550ceab3448665ef6499a706/components/autofill/src/autofill.udl#L59-L76) for an address;
    // all additional data must be computed. On Desktop, computed fields are handled in FormAutofillStorageBase.sys.mjs at the time of saving. Ideally, we should centralize
    // all transformations, computations, and normalization processes within AddressRecord.sys.mjs to maintain a unified implementation across both platforms.
    // This will be addressed in FXCM-810, aiming to simplify our data representation for both credit cards and addresses.
    if (
      FormAutofillUtils.isAddressField(
        this.fieldDetailsManager.activeFieldDetail?.fieldName
      )
    ) {
      AddressRecord.computeFields(payload);
    }
    this.fieldDetailsManager.activeHandler.autofillFormFields(payload);
  }
}

export default FormAutofillChild;
