/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* eslint-disable no-undef,mozilla/balanced-listeners */
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { FormStateManager } from "resource://gre/modules/shared/FormStateManager.sys.mjs";
import { CreditCardRecord } from "resource://gre/modules/shared/CreditCardRecord.sys.mjs";

export class FormAutofillChild {
  constructor(onSubmitCallback, onAutofillCallback) {
    this.onFocusIn = this.onFocusIn.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.onSubmitCallback = onSubmitCallback;
    this.onAutofillCallback = onAutofillCallback;

    this.fieldDetailsManager = new FormStateManager();

    document.addEventListener("focusin", this.onFocusIn);
    document.addEventListener("submit", this.onSubmit);
  }

  _doIdentifyAutofillFields(element) {
    this.fieldDetailsManager.updateActiveInput(element);
    const validDetails =
      this.fieldDetailsManager.identifyAutofillFields(element);

    // Only ping swift if current field is a cc field
    if (validDetails?.find(field => field.element === element)) {
      const fieldNamesWithValues = validDetails?.reduce(
        (acc, field) => ({
          ...acc,
          [field.fieldName]: field.element.value,
        }),
        {}
      );
      // Normalize record format so we always get a consistent
      // credit card record format: {cc-number, cc-name, cc-exp-month, cc-exp-year}
      CreditCardRecord.normalizeFields(fieldNamesWithValues);
      this.onAutofillCallback(fieldNamesWithValues);
    }
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
      this.onSubmitCallback(records.creditCard.map(entry => entry.record));
    }
  }

  fillFormFields(payload) {
    this.fieldDetailsManager.activeHandler.autofillFormFields(payload);
  }
}

export default FormAutofillChild;
