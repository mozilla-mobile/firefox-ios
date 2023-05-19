/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* eslint-disable no-undef,mozilla/balanced-listeners */
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { FormStateManager } from "resource://gre/modules/shared/FormStateManager.sys.mjs";

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
    const validDetails = this.fieldDetailsManager.identifyAutofillFields(
      element
    );

    // Only ping swift if current field is a cc field
    if (validDetails?.find(field => field.elementWeakRef.get() === element)) {
      const fieldNamesWithValues = validDetails?.reduce(
        (acc, field) => ({
          ...acc,
          [field.fieldName]: field.elementWeakRef.get().value,
        }),
        {}
      );
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
    this.fieldDetailsManager.activeHandler.autofillFormFields(
      JSON.parse(payload)
    );
  }

  focusNextInputField() {
    var inputFields = document.getElementsByTagName('input');
    var activeElement = document.activeElement;
    var currentIndex = Array.prototype.indexOf.call(inputFields, activeElement);
    var inputFieldCount = inputFields.length - 1;

    if (currentIndex < inputFieldCount) {
      var nextField = inputFields[currentIndex + 1];
      nextField.focus();
    }
  }

  focusPreviousField() {
    var inputFields = document.getElementsByTagName('input');
    var activeElement = document.activeElement;
    var currentIndex = Array.prototype.indexOf.call(inputFields, activeElement);

    if (currentIndex > 0) {
      var nextField = inputFields[currentIndex - 1];
      nextField.focus();
    }
  }
}

export default FormAutofillChild;
