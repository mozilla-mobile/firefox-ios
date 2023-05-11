/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { creditCardRulesets } from "resource://gre/modules/shared/CreditCardRuleset.sys.mjs";
import { FormAutofillHeuristics } from "resource://gre/modules/shared/FormAutofillHeuristics.sys.mjs";
import { XPCOMUtils } from "resource://gre/modules/XPCOMUtils.sys.mjs";
import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";

const DEFAULT_SECTION_NAME = "-moz-section-default";

/**
 * To help us classify sections, we want to know what fields can appear
 * multiple times in a row.
 * Such fields, like `address-line{X}`, should not break sections.
 */
const MULTI_FIELD_NAMES = [
  "address-level3",
  "address-level2",
  "address-level1",
  "tel",
  "postal-code",
  "email",
  "street-address",
];

/**
 * To help us classify sections that can appear only N times in a row.
 * For example, the only time multiple cc-number fields are valid is when
 * there are four of these fields in a row.
 * Otherwise, multiple cc-number fields should be in separate sections.
 */
const MULTI_N_FIELD_NAMES = {
  "cc-number": 4,
};

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

  isSame(other) {
    return (
      this.fieldName == other.fieldName &&
      this.section == other.section &&
      this.addressType == other.addressType &&
      !this.part &&
      !other.part
    );
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

  #sections = [];

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

  get parsingFinished() {
    return this.parsingIndex >= this.#elements.length;
  }

  #pushToSection(name, fieldDetail) {
    const section = this.#sections.find(s => s.name == name);
    if (section) {
      section.fieldDetails.push(fieldDetail);
      return;
    }
    this.#sections.push({ name, fieldDetails: [fieldDetail] });
  }
  /**
   * Merges the next N fields if the currentType is in the list of MULTI_N_FIELD_NAMES
   *
   * @param {number} mergeNextNFields How many of the next N fields to merge into the current section
   * @param {string} currentType Type of the current field detail
   * @param {Array<object>} fieldDetails List of current field details
   * @param {number} i Index to keep track of the fieldDetails list
   * @param {boolean} createNewSection Determines if a new section should be created
   * @returns {Array<(number|boolean)>} mergeNextNFields and creatNewSection for use in #classifySections
   * @memberof FieldScanner
   */
  #mergeNextNFields(
    mergeNextNFields,
    currentType,
    fieldDetails,
    i,
    createNewSection
  ) {
    if (mergeNextNFields) {
      mergeNextNFields--;
    } else {
      // We use -2 here because we have already seen two consecutive fields,
      // the previous one and the current one.
      // This ensures we don't accidentally add a field we've already seen.
      const nextN = MULTI_N_FIELD_NAMES[currentType] - 2;
      const array = fieldDetails.slice(i + 1, i + 1 + nextN);
      if (
        array.length == nextN &&
        array.every(detail => detail.fieldName == currentType)
      ) {
        mergeNextNFields = nextN;
      } else {
        createNewSection = true;
      }
    }
    return { mergeNextNFields, createNewSection };
  }

  #classifySections() {
    const fieldDetails = this.#sections[0].fieldDetails;
    this.#sections = [];
    let seenTypes = new Set();
    let previousType;
    let sectionCount = 0;
    let mergeNextNFields = 0;

    for (let i = 0; i < fieldDetails.length; i++) {
      let currentType = fieldDetails[i].fieldName;
      if (!currentType) {
        continue;
      }

      let createNewSection = false;
      if (seenTypes.has(currentType)) {
        if (previousType != currentType) {
          // If we have seen this field before and it is different from
          // the previous one, always create a new section.
          createNewSection = true;
        } else if (MULTI_FIELD_NAMES.includes(currentType)) {
          // For fields that can appear multiple times in a row
          // within one section, don't create a new section
        } else if (currentType in MULTI_N_FIELD_NAMES) {
          // This is the heuristic to handle special cases where we can have multiple
          // fields in one section, but only if the field has appeared N times in a row.
          // For example, websites can use 4 consecutive 4-digit `cc-number` fields
          // instead of one 16-digit `cc-number` field.
          ({ mergeNextNFields, createNewSection } = this.#mergeNextNFields(
            mergeNextNFields,
            currentType,
            fieldDetails,
            i,
            createNewSection
          ));
        } else {
          // Fields that should not appear multiple times in one section.
          createNewSection = true;
        }
      }

      if (createNewSection) {
        mergeNextNFields = 0;
        seenTypes.clear();
        sectionCount++;
      }

      previousType = currentType;
      seenTypes.add(currentType);
      this.#pushToSection(
        DEFAULT_SECTION_NAME + "-" + sectionCount,
        fieldDetails[i]
      );
    }
  }

  /**
   * The result is an array contains the sections with its belonging field
   * details. If `this.#sections` contains one section only with the default
   * section name (DEFAULT_SECTION_NAME), `this.#classifySections` should be
   * able to identify all sections in the heuristic way.
   *
   * @returns {Array<object>}
   *          The array with the sections, and the belonging fieldDetails are in
   *          each section. For example, it may return something like this:
   *          [{
   *             type: FormAutofillUtils.SECTION_TYPES.ADDRESS,  // section type
   *             fieldDetails: [{  // a record for each field
   *                 fieldName: "email",
   *                 section: "",
   *                 addressType: "",
   *                 contactType: "",
   *                 elementWeakRef: the element
   *               }, ...]
   *           },
   *           {
   *             type: FormAutofillUtils.SECTION_TYPES.CREDIT_CARD,
   *             fieldDetails: [{
   *                fieldName: "cc-exp-month",
   *                section: "",
   *                addressType: "",
   *                contactType: "",
   *                 elementWeakRef: the element
   *               }, ...]
   *           }]
   */
  getSectionFieldDetails() {
    if (!this.#sections.length) {
      return [];
    }
    if (
      this.#sections.length == 1 &&
      this.#sections[0].name == DEFAULT_SECTION_NAME
    ) {
      this.#classifySections();
    }

    return this.#sections.reduce((sections, current) => {
      sections.push(...this.#getFinalDetails(current.fieldDetails));
      return sections;
    }, []);
  }

  /**
   * This function will prepare an autocomplete info object with getInferredInfo
   * function and push the detail to fieldDetails property.
   * Any field will be pushed into `this.#sections` based on the section name
   * in `autocomplete` attribute.
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
    const [
      fieldName,
      autocompleteInfo,
      confidence,
    ] = FormAutofillHeuristics.getInferredInfo(element, this);
    const fieldDetail = new FieldDetail(element, fieldName, {
      autocompleteInfo,
      confidence,
    });

    this.fieldDetails.push(fieldDetail);
    this.#pushToSection(this.#getSectionName(fieldDetail), fieldDetail);
  }

  #getSectionName(info) {
    let names = [];
    if (info.section) {
      names.push(info.section);
    }
    if (info.addressType) {
      names.push(info.addressType);
    }
    return names.length ? names.join(" ") : DEFAULT_SECTION_NAME;
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

  /**
   * When a site has four credit card number fields and
   * these fields have a max length of four
   * then we transform the credit card number into
   * four subsections in order to fill correctly.
   *
   * @param {Array<object>} creditCardFieldDetails
   *        The credit card field details to be transformed for multiple cc-number fields filling
   * @memberof FieldScanner
   */
  #transformCCNumberForMultipleFields(creditCardFieldDetails) {
    const details = creditCardFieldDetails.filter(
      field =>
        field.fieldName == "cc-number" &&
        field.elementWeakRef.get().maxLength == 4
    );
    if (details.length != 4) {
      return;
    }

    details.map((detail, idx) => {
      detail.part = idx + 1;
    });
  }

  /**
   * Provide the final field details without invalid field name, and the
   * duplicated fields will be removed as well. For the debugging purpose,
   * the final `fieldDetails` will include the duplicated fields if
   * `_allowDuplicates` is true.
   *
   * Each item should contain one type of fields only, and the two valid types
   * are Address and CreditCard.
   *
   * @param   {Array<object>} fieldDetails
   *          The field details for trimming.
   * @returns {Array<object>}
   *          The array with the field details without invalid field name and
   *          duplicated fields.
   */
  #getFinalDetails(fieldDetails) {
    let addressFieldDetails = [];
    let creditCardFieldDetails = [];
    for (const fieldDetail of fieldDetails) {
      const fieldName = fieldDetail.fieldName;
      if (FormAutofillUtils.isAddressField(fieldName)) {
        addressFieldDetails.push(fieldDetail);
      } else if (FormAutofillUtils.isCreditCardField(fieldName)) {
        creditCardFieldDetails.push(fieldDetail);
      } else {
        this.log.debug(
          "Not collecting a field with a unknown fieldName",
          fieldDetail
        );
      }
    }
    this.#transformCCNumberForMultipleFields(creditCardFieldDetails);
    return [
      {
        type: FormAutofillUtils.SECTION_TYPES.ADDRESS,
        fieldDetails: addressFieldDetails,
      },
      {
        type: FormAutofillUtils.SECTION_TYPES.CREDIT_CARD,
        fieldDetails: creditCardFieldDetails,
      },
    ]
      .map(section => {
        // Deduplicate each set of fieldDetails
        const details = section.fieldDetails;
        section.fieldDetails = details.filter((detail, index) => {
          const previousFields = details.slice(0, index);
          return !previousFields.find(f => f.isSame(detail));
        });
        return section;
      })
      .filter(section => !!section.fieldDetails.length);
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
    let highestConfidence = FormAutofillUtils.ccFathomConfidenceThreshold; // Start with a threshold of 0.5
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
    if (FormAutofillUtils.ccFathomTestConfidence > 0) {
      highestConfidence = FormAutofillUtils.ccFathomTestConfidence;
    }

    return [highestField, highestConfidence];
  }

  /**
   * @param {Array} elements Array of elements that we want to get result from fathom cc rules
   * @returns {object} Fathom confidence keyed by field-type.
   */
  static getFormAutofillConfidences(elements) {
    if (
      FormAutofillUtils.ccHeuristicsMode == FormAutofillUtils.CC_FATHOM_NATIVE
    ) {
      const confidences = ChromeUtils.getFormAutofillConfidences(elements);
      return confidences.map(c => {
        let result = {};
        for (let [fieldName, confidence] of Object.entries(c)) {
          let type = FormAutofillUtils.formAutofillConfidencesKeyToCCFieldType(
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
        const ruleset = creditCardRulesets[fieldName];
        const fnodes = ruleset.against(element).get(fieldName);

        // fnodes is either 0 or 1 item long, since we ran the ruleset
        // against a single element:
        return fnodes.length ? fnodes[0].scoreFor(fieldName) : 0;
      }

      // Bang the element against the ruleset for every type of field:
      const confidences = {};
      creditCardRulesets.types.map(fieldName => {
        confidences[fieldName] = confidence(fieldName);
      });

      return confidences;
    });
  }
}

export default FieldScanner;
