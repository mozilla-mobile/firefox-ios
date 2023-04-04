import { FormAutofillHeuristicsShared } from "resource://gre/modules/FormAutofillHeuristics.shared.mjs";
import { FormAutofillUtilsShared } from "resource://gre/modules/FormAutofillUtils.shared.mjs";
import { creditCardRulesets } from "resource://gre/modules/CreditCardRuleset.mjs";
// TODO(HACK): FXIOS-6124
const lazy = { log: { debug: () => {} } };
// TODO(HACK): FXIOS-6124 Update this
// const creditCardRulesets = {
//   types: ["cc-number", "cc-name"],
// };

// TODO(HACK): FXIOS-6124
const fathomTmpValues = {
  ccFathomConfidenceThreshold: 0.5,
  ccFathomTestConfidence: 0.5,
  ccHeuristicsMode: 1,
};
export const DEFAULT_SECTION_NAME = "-moz-section-default";

/**
 * To help us classify sections, we want to know what fields can appear
 * multiple times in a row.
 * Such fields, like `address-line{X}`, should not break sections.
 */
export const MULTI_FIELD_NAMES = [
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
export const MULTI_N_FIELD_NAMES = {
  "cc-number": 4,
};

/**
 * A scanner for traversing all elements in a form and retrieving the field
 * detail with FormAutofillHeuristics.getInfo function. It also provides a
 * cursor (parsingIndex) to indicate which element is waiting for parsing.
 */
export class FieldScanner {
  /**
   * Create a FieldScanner based on form elements with the existing
   * fieldDetails.
   *
   * @param {Array.DOMElement} elements
   *        The elements from a form for each parser.
   */
  constructor(elements, { allowDuplicates = false, sectionEnabled = true }) {
    this._elementsWeakRef = Cu.getWeakReference(elements);
    this.fieldDetails = [];
    this._parsingIndex = 0;
    this._sections = [];
    this._allowDuplicates = allowDuplicates;
    this._sectionEnabled = sectionEnabled;
  }

  get _elements() {
    return this._elementsWeakRef.get();
  }

  /**
   * This cursor means the index of the element which is waiting for parsing.
   *
   * @returns {number}
   *          The index of the element which is waiting for parsing.
   */
  get parsingIndex() {
    return this._parsingIndex;
  }

  /**
   * Move the parsingIndex to the next elements. Any elements behind this index
   * means the parsing tasks are finished.
   *
   * @param {number} index
   *        The latest index of elements waiting for parsing.
   */
  set parsingIndex(index) {
    if (index > this._elements.length) {
      throw new Error("The parsing index is out of range.");
    }
    this._parsingIndex = index;
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
    if (index >= this._elements.length) {
      throw new Error(
        `The index ${index} is out of range.(${this._elements.length})`
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
    return this.parsingIndex >= this._elements.length;
  }

  _pushToSection(name, fieldDetail) {
    for (let section of this._sections) {
      if (section.name == name) {
        section.fieldDetails.push(fieldDetail);
        return;
      }
    }
    this._sections.push({
      name,
      fieldDetails: [fieldDetail],
    });
  }
  /**
   * Merges the next N fields if the currentType is in the list of MULTI_N_FIELD_NAMES
   *
   * @param {number} mergeNextNFields How many of the next N fields to merge into the current section
   * @param {string} currentType Type of the current field detail
   * @param {Array<object>} fieldDetails List of current field details
   * @param {number} i Index to keep track of the fieldDetails list
   * @param {boolean} createNewSection Determines if a new section should be created
   * @returns {Array<(number|boolean)>} mergeNextNFields and creatNewSection for use in _classifySections
   * @memberof FieldScanner
   */
  _mergeNextNFields(
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
      let nextN = MULTI_N_FIELD_NAMES[currentType] - 2;
      let array = fieldDetails.slice(i + 1, i + 1 + nextN);
      if (
        array.length == nextN &&
        array.every((detail) => detail.fieldName == currentType)
      ) {
        mergeNextNFields = nextN;
      } else {
        createNewSection = true;
      }
    }
    return { mergeNextNFields, createNewSection };
  }

  _classifySections() {
    let fieldDetails = this._sections[0].fieldDetails;
    this._sections = [];
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
          ({ mergeNextNFields, createNewSection } = this._mergeNextNFields(
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
      this._pushToSection(
        DEFAULT_SECTION_NAME + "-" + sectionCount,
        fieldDetails[i]
      );
    }
  }

  /**
   * The result is an array contains the sections with its belonging field
   * details. If `this._sections` contains one section only with the default
   * section name (DEFAULT_SECTION_NAME), `this._classifySections` should be
   * able to identify all sections in the heuristic way.
   *
   * @returns {Array<object>}
   *          The array with the sections, and the belonging fieldDetails are in
   *          each section. For example, it may return something like this:
   *          [{
   *             type: FormAutofillUtilsShared.SECTION_TYPES.ADDRESS,  // section type
   *             fieldDetails: [{  // a record for each field
   *                 fieldName: "email",
   *                 section: "",
   *                 addressType: "",
   *                 contactType: "",
   *                 elementWeakRef: the element
   *               }, ...]
   *           },
   *           {
   *             type: FormAutofillUtilsShared.SECTION_TYPES.CREDIT_CARD,
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
    // When the section feature is disabled, `getSectionFieldDetails` should
    // provide a single address and credit card section result.
    if (!this._sectionEnabled) {
      return this._getFinalDetails(this.fieldDetails);
    }
    if (!this._sections.length) {
      return [];
    }
    if (
      this._sections.length == 1 &&
      this._sections[0].name == DEFAULT_SECTION_NAME
    ) {
      this._classifySections();
    }

    return this._sections.reduce((sections, current) => {
      sections.push(...this._getFinalDetails(current.fieldDetails));
      return sections;
    }, []);
  }

  /**
   * This function will prepare an autocomplete info object with getInfo
   * function and push the detail to fieldDetails property.
   * Any field will be pushed into `this._sections` based on the section name
   * in `autocomplete` attribute.
   *
   * Any element without the related detail will be used for adding the detail
   * to the end of field details.
   */
  pushDetail() {
    let elementIndex = this.fieldDetails.length;
    if (elementIndex >= this._elements.length) {
      throw new Error("Try to push the non-existing element info.");
    }
    let element = this._elements[elementIndex];
    let info = FormAutofillHeuristicsShared.getInfo(element, this);
    let fieldInfo = {
      section: info?.section ?? "",
      addressType: info?.addressType ?? "",
      contactType: info?.contactType ?? "",
      fieldName: info?.fieldName ?? "",
      confidence: info?.confidence,
      elementWeakRef: Cu.getWeakReference(element),
    };

    if (info?._reason) {
      fieldInfo._reason = info._reason;
    }

    this.fieldDetails.push(fieldInfo);
    this._pushToSection(this._getSectionName(fieldInfo), fieldInfo);
  }

  _getSectionName(info) {
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

  _isSameField(field1, field2) {
    return (
      field1.section == field2.section &&
      field1.addressType == field2.addressType &&
      field1.fieldName == field2.fieldName &&
      !field1.transform &&
      !field2.transform
    );
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
  _transformCCNumberForMultipleFields(creditCardFieldDetails) {
    let ccNumberFields = creditCardFieldDetails.filter(
      (field) =>
        field.fieldName == "cc-number" &&
        field.elementWeakRef.get().maxLength == 4
    );
    if (ccNumberFields.length == 4) {
      ccNumberFields[0].transform = (fullCCNumber) => fullCCNumber.slice(0, 4);
      ccNumberFields[1].transform = (fullCCNumber) => fullCCNumber.slice(4, 8);
      ccNumberFields[2].transform = (fullCCNumber) => fullCCNumber.slice(8, 12);
      ccNumberFields[3].transform = (fullCCNumber) =>
        fullCCNumber.slice(12, 16);
    }
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
  _getFinalDetails(fieldDetails) {
    let addressFieldDetails = [];
    let creditCardFieldDetails = [];
    for (let fieldDetail of fieldDetails) {
      let fieldName = fieldDetail.fieldName;
      if (FormAutofillUtilsShared.isAddressField(fieldName)) {
        addressFieldDetails.push(fieldDetail);
      } else if (FormAutofillUtilsShared.isCreditCardField(fieldName)) {
        creditCardFieldDetails.push(fieldDetail);
      } else {
        lazy.log.debug(
          "Not collecting a field with a unknown fieldName",
          fieldDetail
        );
      }
    }
    this._transformCCNumberForMultipleFields(creditCardFieldDetails);
    return [
      {
        type: FormAutofillUtilsShared.SECTION_TYPES.ADDRESS,
        fieldDetails: addressFieldDetails,
      },
      {
        type: FormAutofillUtilsShared.SECTION_TYPES.CREDIT_CARD,
        fieldDetails: creditCardFieldDetails,
      },
    ]
      .map((section) => {
        if (this._allowDuplicates) {
          return section;
        }
        // Deduplicate each set of fieldDetails
        let details = section.fieldDetails;
        section.fieldDetails = details.filter((detail, index) => {
          let previousFields = details.slice(0, index);
          return !previousFields.find((f) => this._isSameField(detail, f));
        });
        return section;
      })
      .filter((section) => !!section.fieldDetails.length);
  }

  elementExisting(index) {
    return index < this._elements.length;
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
      if (this._elements?.includes(element)) {
        elements = this._elements;
      } else {
        elements = [element];
      }

      // This should not throw unless we run into an OOM situation, at which
      // point we have worse problems and this failing is not a big deal.
      let confidences = FieldScanner.getFormAutofillConfidences(elements);
      for (let i = 0; i < elements.length; i++) {
        this._fathomConfidences.set(elements[i], confidences[i]);
      }
    }

    let elementConfidences = this._fathomConfidences.get(element);
    if (!elementConfidences) {
      return [null, null];
    }

    let highestField = null;
    // TODO(HACK): FXIOS-6124
    let highestConfidence = fathomTmpValues.ccFathomConfidenceThreshold; // Start with a threshold of 0.5
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

    // // Used by test ONLY! This ensure testcases always get the same confidence
    // TODO(HACK): FXIOS-6124
    // if (fathomTmpValues.ccFathomTestConfidence > 0) {
    //   //TODO(HACK): Update this
    //   highestConfidence = fathomTmpValues.ccFathomTestConfidence;
    // }
    return [highestField, highestConfidence];
  }

  /**
   * @param {Array} elements Array of elements that we want to get result from fathom cc rules
   * @returns {object} Fathom confidence keyed by field-type.
   */
  static getFormAutofillConfidences(elements) {
    // TODO(HACK): FXIOS-6124
    if (
      fathomTmpValues.ccHeuristicsMode ==
      FormAutofillUtilsShared.CC_FATHOM_NATIVE
    ) {
      let confidences = ChromeUtils.getFormAutofillConfidences(elements);
      return confidences.map((c) => {
        let result = {};
        for (let [fieldName, confidence] of Object.entries(c)) {
          let type =
            FormAutofillUtilsShared.formAutofillConfidencesKeyToCCFieldType(
              fieldName
            );
          result[type] = confidence;
        }
        return result;
      });
    }

    return elements.map((element) => {
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
      let confidences = {};
      creditCardRulesets.types.map((fieldName) => {
        confidences[fieldName] = confidence(fieldName);
      });

      return confidences;
    });
  }
}
