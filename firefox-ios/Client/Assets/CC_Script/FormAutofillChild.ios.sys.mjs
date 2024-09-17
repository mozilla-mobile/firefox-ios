/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* eslint-disable no-undef,mozilla/balanced-listeners */
import { AddressRecord } from "resource://gre/modules/shared/AddressRecord.sys.mjs";
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { FormStateManager } from "resource://gre/modules/shared/FormStateManager.sys.mjs";
import { CreditCardRecord } from "resource://gre/modules/shared/CreditCardRecord.sys.mjs";
import {
  FormAutofillAddressSection,
  FormAutofillCreditCardSection,
  FormAutofillSection,
} from "resource://gre/modules/shared/FormAutofillSection.sys.mjs";

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

    this.fieldDetailsManager = new FormStateManager(fieldDetail =>
      // Collect field_modified telemetry
      this.activeSection?.onFilledModified(fieldDetail.elementId)
    );

    try {
      document.addEventListener("focusin", this.onFocusIn);
      document.addEventListener("submit", this.onSubmit);
    } catch {
      // We don't have `document` when running in xpcshell-test
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

  _doIdentifyAutofillFields(element) {
    if (this.#focusedElement == element) {
      return;
    }
    this.#focusedElement = element;

    if (!FormAutofillUtils.isCreditCardOrAddressFieldType(element)) {
      return;
    }

    // Find the autofill handler for this form and identify all the fields.
    const { handler, newFieldsIdentified } =
      this.fieldDetailsManager.identifyAutofillFields(element);

    // If we found newly identified fields, run section classification heuristic
    if (newFieldsIdentified) {
      this.#sections = FormAutofillSection.classifySections(
        handler.fieldDetails
      );

      // For telemetry
      this.#sections.forEach(section => section.onDetected());
    }
  }

  #focusedElement = null;

  // This is a cache contains the classified section for the active form.
  #sections = null;

  get activeSection() {
    const elementId = this.activeFieldDetail?.elementId;
    return this.#sections?.find(section =>
      section.getFieldDetailByElementId(elementId)
    );
  }

  // active field detail only exists if we identified its field name
  get activeFieldDetail() {
    return this.activeHandler?.getFieldDetailByElement(this.#focusedElement);
  }

  get activeHandler() {
    return this.fieldDetailsManager.getFormHandler(this.#focusedElement);
  }

  onFocusIn(evt) {
    const element = evt.target;

    this._doIdentifyAutofillFields(element);

    // Only ping swift if current field is either a cc or address field
    if (!this.activeFieldDetail) {
      return;
    }

    const fieldNamesWithValues = this.transformToFieldNamesWithValues(
      this.activeSection.fieldDetails
    );

    if (FormAutofillUtils.isAddressField(this.activeFieldDetail.fieldName)) {
      this.callbacks.address.autofill(fieldNamesWithValues);
    } else if (
      FormAutofillUtils.isCreditCardField(this.activeFieldDetail.fieldName)
    ) {
      // Normalize record format so we always get a consistent
      // credit card record format: {cc-number, cc-name, cc-exp-month, cc-exp-year}
      CreditCardRecord.normalizeFields(fieldNamesWithValues);
      this.callbacks.creditCard.autofill(fieldNamesWithValues);
    }
  }

  onSubmit(_event) {
    if (!this.activeHandler) {
      return;
    }

    // Get filled value for the form
    const formFilledData = this.activeHandler.collectFormFilledData();

    // Should reference `_onFormSubmit` in `FormAutofillParent.sys.mjs`
    const creditCard = [];

    for (const section of this.#sections) {
      const secRecord = section.createRecord(formFilledData);
      if (!secRecord) {
        continue;
      }

      if (section instanceof FormAutofillAddressSection) {
        // TODO(FXSP-133 Phase 3): Support address capture
        // this.callbacks.address.submit();
        continue;
      } else if (section instanceof FormAutofillCreditCardSection) {
        creditCard.push(secRecord);
      } else {
        throw new Error("Unknown section type");
      }

      section.onSubmitted(formFilledData);
    }

    if (creditCard.length) {
      // Normalize record format so we always get a consistent
      // credit card record format: {cc-number, cc-name, cc-exp-month, cc-exp-year}
      const creditCardRecords = creditCard.map(entry => {
        CreditCardRecord.normalizeFields(entry.record);
        return entry.record;
      });
      this.callbacks.creditCard.submit(creditCardRecords);
    }
  }

  fillFormFields(payload) {
    // In iOS, we have access only to valid fields (https://github.com/mozilla/application-services/blob/9054db4bb5031881550ceab3448665ef6499a706/components/autofill/src/autofill.udl#L59-L76) for an address;
    // all additional data must be computed. On Desktop, computed fields are handled in FormAutofillStorageBase.sys.mjs at the time of saving. Ideally, we should centralize
    // all transformations, computations, and normalization processes within AddressRecord.sys.mjs to maintain a unified implementation across both platforms.
    // This will be addressed in FXCM-810, aiming to simplify our data representation for both credit cards and addresses.

    if (FormAutofillUtils.isAddressField(this.activeFieldDetail?.fieldName)) {
      AddressRecord.computeFields(payload);
    }

    this.activeHandler.fillFields(
      FormAutofillUtils.getElementIdentifier(this.#focusedElement),
      this.activeSection.fieldDetails.map(f => f.elementId),
      payload
    );

    // For telemetry
    const formFilledData = this.activeHandler.collectFormFilledData();
    this.activeSection.onFilled(formFilledData);
  }
}

export default FormAutofillChild;
