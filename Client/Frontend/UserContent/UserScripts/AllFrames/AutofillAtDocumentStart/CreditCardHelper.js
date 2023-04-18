// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";

import { CreditCardAutofill } from "Assets/CC_Script/CreditCardAutofill.js";

class CreditCardHelper {
  constructor() {
    this.onLoad = this.onLoad.bind(this);
    this.onFocus = this.onFocus.bind(this);
    this.creditCardAutofill = new CreditCardAutofill();
    window.addEventListener("load", this.onLoad);
  }

  onLoad() {
    const observer = new MutationObserver((mutations) => {
      for (var idx = 0; idx < mutations.length; ++idx) {
        this.findForms(mutations[idx].addedNodes);
      }
    });
    observer.observe(document.body, {
      attributes: false,
      childList: true,
      characterData: false,
      subtree: true,
    });

    [...document.forms].forEach((form) => {
      const allFields = this.creditCardAutofill.findCreditCardForms(form);
      allFields.forEach((field) =>
        field.addEventListener("focus", this.onFocus)
      );
    });
  }

  onFocus(ev) {
    this.sendMessage({
      msg: "cc-form",
      id: this.creditCardAutofill.getSectionId(ev.target),
    });
  }

  sendMessage(payload) {
    window.webkit.messageHandlers.creditCardMessageHandler?.postMessage(
      payload
    );
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
