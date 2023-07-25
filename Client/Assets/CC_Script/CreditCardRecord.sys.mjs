/* eslint-disable no-useless-concat */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { CreditCard } from "resource://gre/modules/CreditCard.sys.mjs";
import { FormAutofillNameUtils } from "resource://gre/modules/shared/FormAutofillNameUtils.sys.mjs";

/**
 * The CreditCardRecord class serves to handle and normalize internal credit card records.
 * Unlike the CreditCard class, which represents actual card data, CreditCardRecord is used
 * for processing and consistent data representation.
 */
export class CreditCardRecord {
  static normalizeFields(creditCard) {
    this.#normalizeCCNameFields(creditCard);
    this.#normalizeCCNumberFields(creditCard);
    this.#normalizeCCExpirationDateFields(creditCard);
    this.#normalizeCCTypeFields(creditCard);
  }

  static #normalizeCCNameFields(creditCard) {
    if (
      creditCard["cc-given-name"] ||
      creditCard["cc-additional-name"] ||
      creditCard["cc-family-name"]
    ) {
      if (!creditCard["cc-name"]) {
        creditCard["cc-name"] = FormAutofillNameUtils.joinNameParts({
          given: creditCard["cc-given-name"],
          middle: creditCard["cc-additional-name"],
          family: creditCard["cc-family-name"],
        });
      }
    }
    delete creditCard["cc-given-name"];
    delete creditCard["cc-additional-name"];
    delete creditCard["cc-family-name"];
  }

  static #normalizeCCNumberFields(creditCard) {
    if (!("cc-number" in creditCard)) {
      return;
    }

    if (!CreditCard.isValidNumber(creditCard["cc-number"])) {
      delete creditCard["cc-number"];
      return;
    }

    const card = new CreditCard({ number: creditCard["cc-number"] });
    creditCard["cc-number"] = card.number;
  }

  static #normalizeCCExpirationDateFields(creditCard) {
    let normalizedExpiration = CreditCard.normalizeExpiration({
      expirationMonth: creditCard["cc-exp-month"],
      expirationYear: creditCard["cc-exp-year"],
      expirationString: creditCard["cc-exp"],
    });

    creditCard["cc-exp-month"] = normalizedExpiration.month ?? "";
    creditCard["cc-exp-year"] = normalizedExpiration.year ?? "";
    delete creditCard["cc-exp"];
  }

  static #normalizeCCTypeFields(creditCard) {
    // Let's overwrite the credit card type with auto-detect algorithm
    creditCard["cc-type"] = CreditCard.getType(creditCard["cc-number"]) ?? "";
  }
}
