/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { XPCOMUtils } from "resource://gre/modules/XPCOMUtils.sys.mjs";
import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  CreditCardRulesets: "resource://gre/modules/shared/CreditCardRuleset.sys.mjs",
  FormAutofillHeuristics:
    "resource://gre/modules/shared/FormAutofillHeuristics.sys.mjs",
  FormAutofillUtils: "resource://gre/modules/shared/FormAutofillUtils.sys.mjs",
});

export class FormSection {
  static ADDRESS = "address";
  static CREDIT_CARD = "creditCard";

  #fieldDetails = [];

  #name = "";

  constructor(fieldDetails) {
    if (!fieldDetails.length) {
      throw new TypeError("A section should contain at least one field");
    }

    fieldDetails.forEach(field => this.addField(field));

    const fieldName = fieldDetails[0].fieldName;
    if (lazy.FormAutofillUtils.isAddressField(fieldName)) {
      this.type = FormSection.ADDRESS;
    } else if (lazy.FormAutofillUtils.isCreditCardField(fieldName)) {
      this.type = FormSection.CREDIT_CARD;
    } else {
      throw new Error("Unknown field type to create a section.");
    }
  }

  get fieldDetails() {
    return this.#fieldDetails;
  }

  get name() {
    return this.#name;
  }

  addField(fieldDetail) {
    this.#name ||= fieldDetail.sectionName;
    this.#fieldDetails.push(fieldDetail);
  }
}

/**
 * Represents the detailed information about a form field, including
 * the inferred field name, the approach used for inferring, and additional metadata.
 */
export class FieldDetail {
  // Reference to the elemenet
  elementWeakRef = null;

  // The inferred field name for this element
  fieldName = null;

  // The approach we use to infer the information for this element
  // The possible values are "autocomplete", "fathom", and "regex-heuristic"
  reason = null;

  /*
   * The "section", "addressType", and "contactType" values are
   * used to identify the exact field when the serializable data is received
   * from the backend.  There cannot be multiple fields which have
   * the same exact combination of these values.
   */

  // Which section the field belongs to. The value comes from autocomplete attribute.
  // See https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#autofill-detail-tokens for more details
  section = "";
  addressType = "";
  contactType = "";

  // When a field is split into N fields, we use part to record which field it is
  // For example, a credit card number field is split into 4 fields, the value of
  // "part" for the first cc-number field is 1, for the last one is 4.
  // If the field is not split, the value is null
  part = null;

  // Confidence value when the field name is inferred by "fathom"
  confidence = null;

  constructor(
    element,
    fieldName,
    { autocompleteInfo = {}, confidence = null }
  ) {
    this.elementWeakRef = Cu.getWeakReference(element);
    this.fieldName = fieldName;

    if (autocompleteInfo) {
      this.reason = "autocomplete";
      this.section = autocompleteInfo.section;
      this.addressType = autocompleteInfo.addressType;
      this.contactType = autocompleteInfo.contactType;
    } else if (confidence) {
      this.reason = "fathom";
      this.confidence = confidence;
    } else {
      this.reason = "regex-heuristic";
    }
  }

  get element() {
    return this.elementWeakRef.get();
  }

  get sectionName() {
    return this.section || this.addressType;
  }
}

/**
 * A scanner for traversing all elements in a form and retrieving the field
 * detail with FormAutofillHeuristics.getInferredInfo function. It also provides a
 * cursor (parsingIndex) to indicate which element is waiting for parsing.
 */
export class FieldScanner {
  #elementsWeakRef = null;

  #parsingIndex = 0;

  fieldDetails = [];

  /**
   * Create a FieldScanner based on form elements with the existing
   * fieldDetails.
   *
   * @param {Array.DOMElement} elements
   *        The elements from a form for each parser.
   */
  constructor(elements) {
    this.#elementsWeakRef = Cu.getWeakReference(elements);

    XPCOMUtils.defineLazyGetter(this, "log", () =>
      FormAutofill.defineLogGetter(this, "FieldScanner")
    );
  }

  get #elements() {
    return this.#elementsWeakRef.get();
  }

  /**
   * This cursor means the index of the element which is waiting for parsing.
   *
   * @returns {number}
   *          The index of the element which is waiting for parsing.
   */
  get parsingIndex() {
    return this.#parsingIndex;
  }

  get parsingFinished() {
    return this.parsingIndex >= this.#elements.length;
  }

  /**
   * Move the parsingIndex to the next elements. Any elements behind this index
   * means the parsing tasks are finished.
   *
   * @param {number} index
   *        The latest index of elements waiting for parsing.
   */
  set parsingIndex(index) {
    if (index > this.#elements.length) {
      throw new Error("The parsing index is out of range.");
    }
    this.#parsingIndex = index;
  }

  /**
   * Retrieve the field detail by the index. If the field detail is not ready,
   * the elements will be traversed until matching the index.
   *
   * @param {number} index
   *        The index of the element that you want to retrieve.
   * @returns {object}
   *          The field detail at the specific index.
   */
  getFieldDetailByIndex(index) {
    if (index >= this.#elements.length) {
      throw new Error(
        `The index ${index} is out of range.(${this.#elements.length})`
      );
    }

    if (index < this.fieldDetails.length) {
      return this.fieldDetails[index];
    }

    for (let i = this.fieldDetails.length; i < index + 1; i++) {
      this.pushDetail();
    }

    return this.fieldDetails[index];
  }

  /**
   * This function will prepare an autocomplete info object with getInferredInfo
   * function and push the detail to fieldDetails property.
   *
   * Any element without the related detail will be used for adding the detail
   * to the end of field details.
   */
  pushDetail() {
    const elementIndex = this.fieldDetails.length;
    if (elementIndex >= this.#elements.length) {
      throw new Error("Try to push the non-existing element info.");
    }
    const element = this.#elements[elementIndex];
    const [fieldName, autocompleteInfo, confidence] =
      lazy.FormAutofillHeuristics.getInferredInfo(element, this);
    const fieldDetail = new FieldDetail(element, fieldName, {
      autocompleteInfo,
      confidence,
    });

    this.fieldDetails.push(fieldDetail);
  }

  /**
   * When a field detail should be changed its fieldName after parsing, use
   * this function to update the fieldName which is at a specific index.
   *
   * @param {number} index
   *        The index indicates a field detail to be updated.
   * @param {string} fieldName
   *        The new fieldName
   */
  updateFieldName(index, fieldName) {
    if (index >= this.fieldDetails.length) {
      throw new Error("Try to update the non-existing field detail.");
    }
    this.fieldDetails[index].fieldName = fieldName;
  }

  elementExisting(index) {
    return index < this.#elements.length;
  }

  /**
   * Using Fathom, say what kind of CC field an element is most likely to be.
   * This function deoesn't only run fathom on the passed elements. It also
   * runs fathom for all elements in the FieldScanner for optimization purpose.
   *
   * @param {HTMLElement} element
   * @param {Array} fields
   * @returns {Array} A tuple of [field name, probability] describing the
   *   highest-confidence classification
   */
  getFathomField(element, fields) {
    if (!fields.length) {
      return [null, null];
    }

    if (!this._fathomConfidences?.get(element)) {
      this._fathomConfidences = new Map();

      let elements = [];
      if (this.#elements?.includes(element)) {
        elements = this.#elements;
      } else {
        elements = [element];
      }

      // This should not throw unless we run into an OOM situation, at which
      // point we have worse problems and this failing is not a big deal.
      const confidences = FieldScanner.getFormAutofillConfidences(elements);
      for (let i = 0; i < elements.length; i++) {
        this._fathomConfidences.set(elements[i], confidences[i]);
      }
    }

    const elementConfidences = this._fathomConfidences.get(element);
    if (!elementConfidences) {
      return [null, null];
    }

    let highestField = null;
    let highestConfidence = lazy.FormAutofillUtils.ccFathomConfidenceThreshold; // Start with a threshold of 0.5
    for (let [key, value] of Object.entries(elementConfidences)) {
      if (!fields.includes(key)) {
        // ignore field that we don't care
        continue;
      }

      if (value > highestConfidence) {
        highestConfidence = value;
        highestField = key;
      }
    }

    if (!highestField) {
      return [null, null];
    }

    // Used by test ONLY! This ensure testcases always get the same confidence
    if (lazy.FormAutofillUtils.ccFathomTestConfidence > 0) {
      highestConfidence = lazy.FormAutofillUtils.ccFathomTestConfidence;
    }

    return [highestField, highestConfidence];
  }

  /**
   * @param {Array} elements Array of elements that we want to get result from fathom cc rules
   * @returns {object} Fathom confidence keyed by field-type.
   */
  static getFormAutofillConfidences(elements) {
    if (
      lazy.FormAutofillUtils.ccHeuristicsMode ==
      lazy.FormAutofillUtils.CC_FATHOM_NATIVE
    ) {
      const confidences = ChromeUtils.getFormAutofillConfidences(elements);
      return confidences.map(c => {
        let result = {};
        for (let [fieldName, confidence] of Object.entries(c)) {
          let type =
            lazy.FormAutofillUtils.formAutofillConfidencesKeyToCCFieldType(
              fieldName
            );
          result[type] = confidence;
        }
        return result;
      });
    }

    return elements.map(element => {
      /**
       * Return how confident our ML model is that `element` is a field of the
       * given type.
       *
       * @param {string} fieldName The Fathom type to check against. This is
       *   conveniently the same as the autocomplete attribute value that means
       *   the same thing.
       * @returns {number} Confidence in range [0, 1]
       */
      function confidence(fieldName) {
        const ruleset = lazy.CreditCardRulesets[fieldName];
        const fnodes = ruleset.against(element).get(fieldName);

        // fnodes is either 0 or 1 item long, since we ran the ruleset
        // against a single element:
        return fnodes.length ? fnodes[0].scoreFor(fieldName) : 0;
      }

      // Bang the element against the ruleset for every type of field:
      const confidences = {};
      lazy.CreditCardRulesets.types.map(fieldName => {
        confidences[fieldName] = confidence(fieldName);
      });

      return confidences;
    });
  }
}

export default FieldScanner;
