// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";

import { CreditCardAutofill } from "Assets/CC_Script/CreditCardAutofill.js";

const messageTypes = {
  FILL_CREDIT_CARD_FORM: "fill-credit-card-form",
  CAPTURE_CREDIT_CARD_FORM: "capture-credit-card-form",
};

// TODO(HACK): FXIOS-6124 Extract this to its own module
const sendMessage = (type) => (payload) =>
  window.webkit.messageHandlers.creditCardMessageHandler?.postMessage({
    type,
    payload,
  });

const sendCaptureCreditCardFormMessage = sendMessage(
  messageTypes.CAPTURE_CREDIT_CARD_FORM
);

const sendFillCreditCardFormMessage = sendMessage(
  messageTypes.FILL_CREDIT_CARD_FORM
);

class CreditCardHelper {
  constructor() {
    this.creditCardAutofill = new CreditCardAutofill();
    this.onLoad = this.onLoad.bind(this);
    this.onFocus = this.onFocus.bind(this);
    this.onSumbit = this.onSumbit.bind(this);
    window.addEventListener("load", this.onLoad);
    window.addEventListener("submit", this.onSumbit);
  }

  attachFieldListeners() {
    [...document.forms].forEach((form) => {
      const { formInfo } = this.creditCardAutofill.getSection(form);
      if (formInfo) return;
      const allFields = this.creditCardAutofill.findCreditCardForms(form);
      allFields.forEach((field) => (field.onfocus = this.onFocus));
      form.submit = (ev) => this.onSumbit(ev, "submit");
    });
  }

  onLoad() {
    // TODO: This is a hack to detect when the DOM changes,
    const observer = new MutationObserver((mutations) => {
      for (var idx = 0; idx < mutations.length; ++idx) {
        this.attachFieldListeners();
      }
    });
    observer.observe(document.body, {
      attributes: false,
      childList: true,
      characterData: false,
      subtree: true,
    });
    this.attachFieldListeners();
  }

  fieldsToPayload(fields) {
    return fields.map((field) => ({
      type: field.fieldName,
      value: field.elementWeakRef.get().value,
    }));
  }

  onFocus(ev) {
    const { id, formInfo } = this.creditCardAutofill.getSection(ev.target.form);
    if (!formInfo) return;
    sendFillCreditCardFormMessage({
      id,
      fieldTypes: this.fieldsToPayload(formInfo.fields),
    });
  }

  onSumbit(ev) {
    // This is a hack to prevent the form from submitting,
    // we need to find a better way to intercept the submit event
    ev.preventDefault();
    const rootForm = ev.target.tagName === "FORM" ? ev.target : ev.target.form;
    const { id, formInfo } = this.creditCardAutofill.getSection(rootForm);
    if (!formInfo) return;
    sendCaptureCreditCardFormMessage({
      id,
      fieldTypes: this.fieldsToPayload(formInfo.fields),
    });
  }

  fillCreditCardInfo(payload) {
    this.creditCardAutofill.fillCreditCardInfo(payload);
  }
}

Object.defineProperty(window.__firefox__, "CreditCardHelper", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(new CreditCardHelper()),
});
