/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

import { FormAutofillHeuristicsShared } from "Assets/CC_Script/FormAutofillHeuristics.shared.mjs";
class CreditCardHelper {
  constructor() {
    console.log(FormAutofillHeuristicsShared); // Just to make sure it's imported correctly
    window.addEventListener("load", () => {
      this.sendMessage({
        msg: `${new Date().toGMTString()}: ping!!`,
      });
    });
  }
  //   const findForms = (nodes) => {
  //     for (var i = 0; i < nodes.length; i++) {
  //       var node = nodes[i];
  //       if (node.nodeName === "FORM") {
  //         webkit.messageHandlers.creditCardMessageHandler.postMessage(
  //       } else if (node.hasChildNodes()) {
  //         findForms(node.childNodes);
  //       }
  //     }
  //     return false;
  //   };

  //   const observer = new MutationObserver((mutations) => {
  //     for (var idx = 0; idx < mutations.length; ++idx) {
  //       findForms(mutations[idx].addedNodes);
  //     }
  //   });

  sendMessage(payload) {
    window.webkit.messageHandlers.creditCardMessageHandler.postMessage(payload);
  }

  fillCreditCardInfo(payload) {
    alert(`Called from swift result: ${JSON.stringify(payload)}`);
  }
}

Object.defineProperty(window.__firefox__, "CreditCardHelper", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(new CreditCardHelper()),
});
