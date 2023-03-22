/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

import "Assets/CC_Script/shims.js";
import { FormAutofillHeuristicsShared } from "Assets/CC_Script/FormAutofillHeuristics.shared.mjs";
import { FormAutofillUtilsShared } from "Assets/CC_Script/FormAutofillUtils.shared.mjs";

export class CreditCardAutofill {
  constructor() {
    this.creditCardSections = [];
  }

  findForms(nodes) {
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node.nodeName === "FORM") {
        this.findCreditCardForms(node);
      } else if (node.hasChildNodes()) {
        this.findForms(node.childNodes);
      }
    }
    return false;
  }

  findCreditCardForms(form) {
    const sections = FormAutofillHeuristicsShared.getFormInfo(form);
    const _creditCardSections = sections.filter(
      (section) =>
        section.type == FormAutofillUtilsShared.SECTION_TYPES.CREDIT_CARD
    );
    const fieldsMap = _creditCardSections.map(
      (creditCardSection) => creditCardSection.fieldDetails
    );
    const allFields = fieldsMap.flatMap((fields) =>
      fields.map(this.getFieldRef)
    );
    this.creditCardSections.push({ form, fields: fieldsMap[0] }); // Hacky: This is for PoC only
    return allFields;
  }

  getFieldRef(field) {
    return field.elementWeakRef.get();
  }

  getSectionId(form) {
    const sectionId = this.creditCardSections.findIndex(
      (creditCardSection) => creditCardSection.form === form
    );
    return sectionId;
  }

  getSection(form) {
    const sectionId = this.getSectionId(form);
    return { id: sectionId, formInfo: this.creditCardSections[sectionId] };
  }

  fillCCFormFields(fields, data) {
    for (let field of fields) {
      const fieldRef = this.getFieldRef(field);
      if (field.fieldName in data) {
        fieldRef.value = data[field.fieldName];
      }
    }
  }

  fillCreditCardInfo(payload) {
    const { id, data } = JSON.parse(payload);
    this.fillCCFormFields(this.creditCardSections?.[id], data);
  }
}
