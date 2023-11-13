/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";
import { HeuristicsRegExp } from "resource://gre/modules/shared/HeuristicsRegExp.sys.mjs";

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  CreditCard: "resource://gre/modules/CreditCard.sys.mjs",
  CreditCardRulesets: "resource://gre/modules/shared/CreditCardRuleset.sys.mjs",
  FieldScanner: "resource://gre/modules/shared/FieldScanner.sys.mjs",
  FormAutofillUtils: "resource://gre/modules/shared/FormAutofillUtils.sys.mjs",
  LabelUtils: "resource://gre/modules/shared/LabelUtils.sys.mjs",
});

ChromeUtils.defineLazyGetter(lazy, "log", () =>
  FormAutofill.defineLogGetter(lazy, "FormAutofillHeuristics")
);

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
 * Returns the autocomplete information of fields according to heuristics.
 */
export const FormAutofillHeuristics = {
  RULES: HeuristicsRegExp.getRules(),
  LABEL_RULES: HeuristicsRegExp.getLabelRules(),

  CREDIT_CARD_FIELDNAMES: [],
  ADDRESS_FIELDNAMES: [],
  /**
   * Try to find a contiguous sub-array within an array.
   *
   * @param {Array} array
   * @param {Array} subArray
   *
   * @returns {boolean}
   *          Return whether subArray was found within the array or not.
   */
  _matchContiguousSubArray(array, subArray) {
    return array.some((elm, i) =>
      subArray.every((sElem, j) => sElem == array[i + j])
    );
  },

  /**
   * Try to find the field that is look like a month select.
   *
   * @param {DOMElement} element
   * @returns {boolean}
   *          Return true if we observe the trait of month select in
   *          the current element.
   */
  _isExpirationMonthLikely(element) {
    if (!HTMLSelectElement.isInstance(element)) {
      return false;
    }

    const options = [...element.options];
    const desiredValues = Array(12)
      .fill(1)
      .map((v, i) => v + i);

    // The number of month options shouldn't be less than 12 or larger than 13
    // including the default option.
    if (options.length < 12 || options.length > 13) {
      return false;
    }

    return (
      this._matchContiguousSubArray(
        options.map(e => +e.value),
        desiredValues
      ) ||
      this._matchContiguousSubArray(
        options.map(e => +e.label),
        desiredValues
      )
    );
  },

  /**
   * Try to find the field that is look like a year select.
   *
   * @param {DOMElement} element
   * @returns {boolean}
   *          Return true if we observe the trait of year select in
   *          the current element.
   */
  _isExpirationYearLikely(element) {
    if (!HTMLSelectElement.isInstance(element)) {
      return false;
    }

    const options = [...element.options];
    // A normal expiration year select should contain at least the last three years
    // in the list.
    const curYear = new Date().getFullYear();
    const desiredValues = Array(3)
      .fill(0)
      .map((v, i) => v + curYear + i);

    return (
      this._matchContiguousSubArray(
        options.map(e => +e.value),
        desiredValues
      ) ||
      this._matchContiguousSubArray(
        options.map(e => +e.label),
        desiredValues
      )
    );
  },

  /**
   * Try to match the telephone related fields to the grammar
   * list to see if there is any valid telephone set and correct their
   * field names.
   *
   * @param {FieldScanner} scanner
   *        The current parsing status for all elements
   * @returns {boolean}
   *          Return true if there is any field can be recognized in the parser,
   *          otherwise false.
   */
  _parsePhoneFields(scanner, detail) {
    let matchingResult;
    const GRAMMARS = this.PHONE_FIELD_GRAMMARS;

    function isGrammarSeparator(index) {
      return !GRAMMARS[index][0];
    }

    const savedIndex = scanner.parsingIndex;
    for (let ruleFrom = 0; ruleFrom < GRAMMARS.length; ) {
      const detailStart = scanner.parsingIndex;
      let ruleTo = ruleFrom;
      for (let count = 0; ruleTo < GRAMMARS.length; ruleTo++, count++) {
        // Bail out when reaching the end of the current set of grammars
        // or there are no more elements to parse
        if (
          isGrammarSeparator(ruleTo) ||
          !scanner.elementExisting(detailStart + count)
        ) {
          break;
        }

        const [category, , length] = GRAMMARS[ruleTo];
        const detail = scanner.getFieldDetailByIndex(detailStart + count);

        // If the field is not what this grammar rule is interested in, skip processing.
        if (
          !detail ||
          detail.fieldName != category ||
          detail.reason == "autocomplete"
        ) {
          break;
        }

        const element = detail.element;
        if (length && (!element.maxLength || length < element.maxLength)) {
          break;
        }
      }

      // if we reach the grammar separator, that means all the previous rules are matched.
      // Set the matchingResult so we update field names accordingly.
      if (isGrammarSeparator(ruleTo)) {
        matchingResult = { ruleFrom, ruleTo };
        break;
      }

      // Fast forward to the next rule set.
      for (; ruleFrom < GRAMMARS.length; ) {
        if (isGrammarSeparator(ruleFrom++)) {
          break;
        }
      }
    }

    if (matchingResult) {
      const { ruleFrom, ruleTo } = matchingResult;
      for (let i = ruleFrom; i < ruleTo; i++) {
        scanner.updateFieldName(scanner.parsingIndex, GRAMMARS[i][1]);
        scanner.parsingIndex++;
      }
    }

    // If the previous parsed field is a "tel" field, run heuristic to see
    // if the current field is a "tel-extension" field
    const field = scanner.getFieldDetailByIndex(scanner.parsingIndex);
    if (field && field.reason != "autocomplete") {
      const prev = scanner.getFieldDetailByIndex(scanner.parsingIndex - 1);
      if (
        prev &&
        lazy.FormAutofillUtils.getCategoryFromFieldName(prev.fieldName) == "tel"
      ) {
        const regExpTelExtension = new RegExp(
          "\\bext|ext\\b|extension|ramal", // pt-BR, pt-PT
          "iug"
        );
        if (this._matchRegexp(field.element, regExpTelExtension)) {
          scanner.updateFieldName(scanner.parsingIndex, "tel-extension");
          scanner.parsingIndex++;
        }
      }
    }
    return savedIndex != scanner.parsingIndex;
  },

  /**
   * Try to find the correct address-line[1-3] sequence and correct their field
   * names.
   *
   * @param {FieldScanner} scanner
   *        The current parsing status for all elements
   * @returns {boolean}
   *          Return true if there is any field can be recognized in the parser,
   *          otherwise false.
   */
  _parseStreetAddressFields(scanner, fieldDetail) {
    const INTERESTED_FIELDS = [
      "street-address",
      "address-line1",
      "address-line2",
      "address-line3",
    ];

    const fields = [];
    for (let idx = scanner.parsingIndex; !scanner.parsingFinished; idx++) {
      const detail = scanner.getFieldDetailByIndex(idx);
      if (!INTERESTED_FIELDS.includes(detail?.fieldName)) {
        break;
      }
      fields.push(detail);
    }

    if (!fields.length) {
      return false;
    }

    switch (fields.length) {
      case 1:
        if (
          fields[0].reason != "autocomplete" &&
          ["address-line2", "address-line3"].includes(fields[0].fieldName)
        ) {
          scanner.updateFieldName(scanner.parsingIndex, "address-line1");
        }
        break;
      case 2:
        if (fields[0].reason == "autocomplete") {
          if (
            fields[0].fieldName == "street-address" &&
            (fields[1].fieldName == "address-line2" ||
              fields[1].reason != "autocomplete")
          ) {
            scanner.updateFieldName(
              scanner.parsingIndex,
              "address-line1",
              true
            );
          }
        } else {
          scanner.updateFieldName(scanner.parsingIndex, "address-line1");
        }

        scanner.updateFieldName(scanner.parsingIndex + 1, "address-line2");
        break;
      case 3:
      default:
        scanner.updateFieldName(scanner.parsingIndex, "address-line1");
        scanner.updateFieldName(scanner.parsingIndex + 1, "address-line2");
        scanner.updateFieldName(scanner.parsingIndex + 2, "address-line3");
        break;
    }

    scanner.parsingIndex += fields.length;
    return true;
  },

  _parseAddressFields(scanner, fieldDetail) {
    const INTERESTED_FIELDS = ["address-level1", "address-level2"];

    if (!INTERESTED_FIELDS.includes(fieldDetail.fieldName)) {
      return false;
    }

    const fields = [];
    for (let idx = scanner.parsingIndex; !scanner.parsingFinished; idx++) {
      const detail = scanner.getFieldDetailByIndex(idx);
      if (!INTERESTED_FIELDS.includes(detail?.fieldName)) {
        break;
      }
      fields.push(detail);
    }

    if (!fields.length) {
      return false;
    }

    // State & City(address-level2)
    if (fields.length == 1) {
      if (fields[0].fieldName == "address-level2") {
        const prev = scanner.getFieldDetailByIndex(scanner.parsingIndex - 1);
        if (
          prev &&
          !prev.fieldName &&
          HTMLSelectElement.isInstance(prev.element)
        ) {
          scanner.updateFieldName(scanner.parsingIndex - 1, "address-level1");
          scanner.parsingIndex += 1;
          return true;
        }
        const next = scanner.getFieldDetailByIndex(scanner.parsingIndex + 1);
        if (
          next &&
          !next.fieldName &&
          HTMLSelectElement.isInstance(next.element)
        ) {
          scanner.updateFieldName(scanner.parsingIndex + 1, "address-level1");
          scanner.parsingIndex += 2;
          return true;
        }
      }
    }

    scanner.parsingIndex += fields.length;
    return true;
  },

  /**
   * Try to look for expiration date fields and revise the field names if needed.
   *
   * @param {FieldScanner} scanner
   *        The current parsing status for all elements
   * @returns {boolean}
   *          Return true if there is any field can be recognized in the parser,
   *          otherwise false.
   */
  _parseCreditCardExpiryFields(scanner, fieldDetail) {
    const INTERESTED_FIELDS = ["cc-exp", "cc-exp-month", "cc-exp-year"];

    if (!INTERESTED_FIELDS.includes(fieldDetail.fieldName)) {
      return false;
    }

    const fields = [];
    for (let idx = scanner.parsingIndex; ; idx++) {
      const detail = scanner.getFieldDetailByIndex(idx);
      if (!INTERESTED_FIELDS.includes(detail?.fieldName)) {
        break;
      }
      fields.push(detail);
    }

    // Don't process the fields if expiration month and expiration year are already
    // matched by regex in correct order.
    if (
      (fields.length == 1 && fields[0].fieldName == "cc-exp") ||
      (fields.length == 2 &&
        fields[0].fieldName == "cc-exp-month" &&
        fields[1].fieldName == "cc-exp-year")
    ) {
      scanner.parsingIndex += fields.length;
      return true;
    }

    const prevCCFields = new Set();
    for (let idx = scanner.parsingIndex - 1; ; idx--) {
      const detail = scanner.getFieldDetailByIndex(idx);
      if (
        lazy.FormAutofillUtils.getCategoryFromFieldName(detail?.fieldName) !=
        "creditCard"
      ) {
        break;
      }
      prevCCFields.add(detail.fieldName);
    }
    // We update the "cc-exp-*" fields to correct "cc-ex-*" fields order when
    // the following conditions are met:
    // 1. The previous elements are identified as credit card fields and
    //    cc-number is in it
    // 2. There is no "cc-exp-*" fields in the previous credit card elements
    if (
      ["cc-number", "cc-name"].some(f => prevCCFields.has(f)) &&
      !["cc-exp", "cc-exp-month", "cc-exp-year"].some(f => prevCCFields.has(f))
    ) {
      if (fields.length == 1) {
        scanner.updateFieldName(scanner.parsingIndex, "cc-exp");
      } else if (fields.length == 2) {
        scanner.updateFieldName(scanner.parsingIndex, "cc-exp-month");
        scanner.updateFieldName(scanner.parsingIndex + 1, "cc-exp-year");
      }
      scanner.parsingIndex += fields.length;
      return true;
    }

    // Set field name to null as it failed to match any patterns.
    for (let idx = 0; idx < fields.length; idx++) {
      scanner.updateFieldName(scanner.parsingIndex + idx, null);
    }
    return false;
  },

  /**
   * Look for cc-*-name fields when *-name field is present
   *
   * @param {FieldScanner} scanner
   *        The current parsing status for all elements
   * @returns {boolean}
   *          Return true if there is any field can be recognized in the parser,
   *          otherwise false.
   */
  _parseCreditCardNameFields(scanner, fieldDetail) {
    const INTERESTED_FIELDS = [
      "name",
      "given-name",
      "additional-name",
      "family-name",
    ];

    if (!INTERESTED_FIELDS.includes(fieldDetail.fieldName)) {
      return false;
    }

    const fields = [];
    for (let idx = scanner.parsingIndex; ; idx++) {
      const detail = scanner.getFieldDetailByIndex(idx);
      if (!INTERESTED_FIELDS.includes(detail?.fieldName)) {
        break;
      }
      fields.push(detail);
    }

    const prevCCFields = new Set();
    for (let idx = scanner.parsingIndex - 1; ; idx--) {
      const detail = scanner.getFieldDetailByIndex(idx);
      if (
        lazy.FormAutofillUtils.getCategoryFromFieldName(detail?.fieldName) !=
        "creditCard"
      ) {
        break;
      }
      prevCCFields.add(detail.fieldName);
    }

    // We update the "name" fields to "cc-name" fields when the following
    // conditions are met:
    // 1. The preceding fields are identified as credit card fields and
    //    contain the "cc-number" field.
    // 2. No "cc-name-*" field is found among the preceding credit card fields.
    // 3. The "cc-csc" field is not present among the preceding credit card fields.
    if (
      ["cc-number"].some(f => prevCCFields.has(f)) &&
      !["cc-name", "cc-given-name", "cc-family-name", "cc-csc"].some(f =>
        prevCCFields.has(f)
      )
    ) {
      // If there is only one field, assume the name field a `cc-name` field
      if (fields.length == 1) {
        scanner.updateFieldName(scanner.parsingIndex, `cc-name`);
        scanner.parsingIndex += 1;
      } else {
        // update *-name to cc-*-name
        for (const field of fields) {
          scanner.updateFieldName(
            scanner.parsingIndex,
            `cc-${field.fieldName}`
          );
          scanner.parsingIndex += 1;
        }
      }
      return true;
    }

    return false;
  },

  /**
   * This function should provide all field details of a form which are placed
   * in the belonging section. The details contain the autocomplete info
   * (e.g. fieldName, section, etc).
   *
   * @param {HTMLFormElement} form
   *        the elements in this form to be predicted the field info.
   * @returns {Array<FormSection>}
   *        all sections within its field details in the form.
   */
  getFormInfo(form) {
    let elements = this.getFormElements(form);

    const scanner = new lazy.FieldScanner(elements, element =>
      this.inferFieldInfo(element, elements)
    );

    while (!scanner.parsingFinished) {
      const savedIndex = scanner.parsingIndex;

      // First, we get the inferred field info
      const fieldDetail = scanner.getFieldDetailByIndex(scanner.parsingIndex);

      if (
        this._parsePhoneFields(scanner, fieldDetail) ||
        this._parseStreetAddressFields(scanner, fieldDetail) ||
        this._parseAddressFields(scanner, fieldDetail) ||
        this._parseCreditCardExpiryFields(scanner, fieldDetail) ||
        this._parseCreditCardNameFields(scanner, fieldDetail)
      ) {
        continue;
      }

      // If there is no field parsed, the parsing cursor can be moved
      // forward to the next one.
      if (savedIndex == scanner.parsingIndex) {
        scanner.parsingIndex++;
      }
    }

    lazy.LabelUtils.clearLabelMap();

    const fields = scanner.fieldDetails;
    const sections = [
      ...this._classifySections(
        fields.filter(f => lazy.FormAutofillUtils.isAddressField(f.fieldName))
      ),
      ...this._classifySections(
        fields.filter(f =>
          lazy.FormAutofillUtils.isCreditCardField(f.fieldName)
        )
      ),
    ];

    return sections.sort(
      (a, b) =>
        fields.indexOf(a.fieldDetails[0]) - fields.indexOf(b.fieldDetails[0])
    );
  },

  /**
   * Get form elements that are of credit card or address type and filtered by either
   * visibility or focusability - depending on the interactivity mode (default = focusability)
   * This distinction is only temporary as we want to test switching from visibility mode
   * to focusability mode. The visibility mode is then removed.
   *
   * @param {HTMLElement} form
   * @returns {Array<HTMLElement>} elements filtered by interactivity mode (visibility or focusability)
   */
  getFormElements(form) {
    let elements = Array.from(form.elements).filter(element =>
      lazy.FormAutofillUtils.isCreditCardOrAddressFieldType(element)
    );
    const interactivityMode = lazy.FormAutofillUtils.interactivityCheckMode;

    if (interactivityMode == "focusability") {
      elements = elements.filter(element =>
        lazy.FormAutofillUtils.isFieldFocusable(element)
      );
    } else if (interactivityMode == "visibility") {
      // Due to potential performance impact while running visibility check on
      // a large amount of elements, a comprehensive visibility check
      // (considering opacity and CSS visibility) is only applied when the number
      // of eligible elements is below a certain threshold.
      const runVisiblityCheck =
        elements.length < lazy.FormAutofillUtils.visibilityCheckThreshold;
      if (!runVisiblityCheck) {
        lazy.log.debug(
          `Skip running visibility check, because of too many elements (${elements.length})`
        );
      }
      elements = elements.filter(element =>
        lazy.FormAutofillUtils.isFieldVisible(element, runVisiblityCheck)
      );
    }
    return elements;
  },

  /**
   * The result is an array contains the sections with its belonging field details.
   *
   * @param   {Array<FieldDetails>} fieldDetails field detail array to be classified
   * @returns {Array<FormSection>} The array with the sections.
   */
  _classifySections(fieldDetails) {
    let sections = [];
    for (let i = 0; i < fieldDetails.length; i++) {
      const fieldName = fieldDetails[i].fieldName;
      const sectionName = fieldDetails[i].sectionName;

      const [currentSection] = sections.slice(-1);

      // The section this field might belong to
      let candidateSection = null;

      // If the field doesn't have a section name, MAYBE put it to the previous
      // section if exists. If the field has a section name, maybe put it to the
      // nearest section that either has the same name or it doesn't has a name.
      // Otherwise, create a new section.
      if (!currentSection || !sectionName) {
        candidateSection = currentSection;
      } else if (sectionName) {
        for (let idx = sections.length - 1; idx >= 0; idx--) {
          if (!sections[idx].name || sections[idx].name == sectionName) {
            candidateSection = sections[idx];
            break;
          }
        }
      }

      // We got an candidate section to put the field to, check whether the section
      // already has a field with the same field name. If yes, only add the field to when
      // the type of the field might appear multiple times in a row.
      if (candidateSection) {
        let createNewSection = true;
        if (candidateSection.fieldDetails.find(f => f.fieldName == fieldName)) {
          const [lastFieldDetail] = candidateSection.fieldDetails.slice(-1);
          if (lastFieldDetail.fieldName == fieldName) {
            if (MULTI_FIELD_NAMES.includes(fieldName)) {
              createNewSection = false;
            } else if (fieldName in MULTI_N_FIELD_NAMES) {
              // This is the heuristic to handle special cases where we can have multiple
              // fields in one section, but only if the field has appeared N times in a row.
              // For example, websites can use 4 consecutive 4-digit `cc-number` fields
              // instead of one 16-digit `cc-number` field.

              const N = MULTI_N_FIELD_NAMES[fieldName];
              if (lastFieldDetail.part) {
                // If `part` is set, we have already identified this field can be
                // merged previously
                if (lastFieldDetail.part < N) {
                  createNewSection = false;
                  fieldDetails[i].part = lastFieldDetail.part + 1;
                }
                // If the next N fields are all the same field, we can merge them
              } else if (
                N == 2 ||
                fieldDetails
                  .slice(i + 1, i + N - 1)
                  .every(f => f.fieldName == fieldName)
              ) {
                lastFieldDetail.part = 1;
                fieldDetails[i].part = 2;
                createNewSection = false;
              }
            }
          }
        } else {
          // The field doesn't exist in the candidate section, add it.
          createNewSection = false;
        }

        if (!createNewSection) {
          candidateSection.addField(fieldDetails[i]);
          continue;
        }
      }

      // Create a new section
      sections.push(new FormSection([fieldDetails[i]]));
    }

    return sections;
  },

  _getPossibleFieldNames(element) {
    let fieldNames = [];
    const isAutoCompleteOff =
      element.autocomplete == "off" || element.form?.autocomplete == "off";
    if (!isAutoCompleteOff || FormAutofill.creditCardsAutocompleteOff) {
      fieldNames.push(...this.CREDIT_CARD_FIELDNAMES);
    }
    if (!isAutoCompleteOff || FormAutofill.addressesAutocompleteOff) {
      fieldNames.push(...this.ADDRESS_FIELDNAMES);
    }

    if (HTMLSelectElement.isInstance(element)) {
      const FIELDNAMES_FOR_SELECT_ELEMENT = [
        "address-level1",
        "address-level2",
        "country",
        "cc-exp-month",
        "cc-exp-year",
        "cc-exp",
        "cc-type",
      ];
      fieldNames = fieldNames.filter(name =>
        FIELDNAMES_FOR_SELECT_ELEMENT.includes(name)
      );
    }

    return fieldNames;
  },

  /**
   * Get inferred information about an input element using autocomplete info, fathom and regex-based heuristics.
   *
   * @param {HTMLElement} element - The input element to infer information about.
   * @param {Array<HTMLElement>} elements - See `getFathomField` for details
   * @returns {Array} - An array containing:
   *                    [0]the inferred field name
   *                    [1]autocomplete information if the element has autocompelte attribute, null otherwise.
   *                    [2]fathom confidence if fathom considers it a cc field, null otherwise.
   */
  inferFieldInfo(element, elements = []) {
    const autocompleteInfo = element.getAutocompleteInfo();

    // An input[autocomplete="on"] will not be early return here since it stll
    // needs to find the field name.
    if (
      autocompleteInfo?.fieldName &&
      !["on", "off"].includes(autocompleteInfo.fieldName)
    ) {
      return [autocompleteInfo.fieldName, autocompleteInfo, null];
    }

    const fields = this._getPossibleFieldNames(element);

    // "email" type of input is accurate for heuristics to determine its Email
    // field or not. However, "tel" type is used for ZIP code for some web site
    // (e.g. HomeDepot, BestBuy), so "tel" type should be not used for "tel"
    // prediction.
    if (element.type == "email" && fields.includes("email")) {
      return ["email", null, null];
    }

    if (lazy.FormAutofillUtils.isFathomCreditCardsEnabled()) {
      // We don't care fields that are not supported by fathom
      const fathomFields = fields.filter(r =>
        lazy.CreditCardRulesets.types.includes(r)
      );
      const [matchedFieldName, confidence] = this.getFathomField(
        element,
        fathomFields,
        elements
      );
      // At this point, use fathom's recommendation if it has one
      if (matchedFieldName) {
        return [matchedFieldName, null, confidence];
      }

      // Continue to run regex-based heuristics even when fathom doesn't recognize
      // the field. Since the regex-based heuristic has good search coverage but
      // has a worse precision. We use it in conjunction with fathom to maximize
      // our search coverage. For example, when a <input> is not considered cc-name
      // by fathom but is considered cc-name by regex-based heuristic, if the form
      // also contains a cc-number identified by fathom, we will treat the form as a
      // valid cc form; hence both cc-number & cc-name are identified.
    }

    // Check every select for options that
    // match credit card network names in value or label.
    if (HTMLSelectElement.isInstance(element)) {
      if (this._isExpirationMonthLikely(element)) {
        return ["cc-exp-month", null, null];
      } else if (this._isExpirationYearLikely(element)) {
        return ["cc-exp-year", null, null];
      }

      const options = Array.from(element.querySelectorAll("option"));
      if (
        options.find(
          option =>
            lazy.CreditCard.getNetworkFromName(option.value) ||
            lazy.CreditCard.getNetworkFromName(option.text)
        )
      ) {
        return ["cc-type", null, null];
      }

      // At least two options match the country name, otherwise some state name might
      // also match a country name, ex, Georgia
      const countryDisplayNames = Array.from(FormAutofill.countries.values());
      if (
        options.length >= 2 &&
        options
          .slice(0, 2)
          .every(
            option =>
              countryDisplayNames.includes(option.value) ||
              countryDisplayNames.includes(option.text)
          )
      ) {
        return ["country", null, null];
      }
    }

    // Find a matched field name using regexp-based heuristics
    const matchedFieldName = this._findMatchedFieldName(element, fields);
    return [matchedFieldName, null, null];
  },

  /**
   * Using Fathom, say what kind of CC field an element is most likely to be.
   * This function deoesn't only run fathom on the passed elements. It also
   * runs fathom for all elements in the FieldScanner for optimization purpose.
   *
   * @param {HTMLElement} element
   * @param {Array} fields
   * @param {Array<HTMLElement>} elements - All other eligible elements in the same form. This is mainly used as an
   *                                        optimization approach to run fathom model on all eligible elements
   *                                        once instead of one by one
   * @returns {Array} A tuple of [field name, probability] describing the
   *   highest-confidence classification
   */
  getFathomField(element, fields, elements = []) {
    if (!fields.length) {
      return [null, null];
    }

    if (!this._fathomConfidences?.get(element)) {
      this._fathomConfidences = new Map();

      // This should not throw unless we run into an OOM situation, at which
      // point we have worse problems and this failing is not a big deal.
      elements = elements.includes(element) ? elements : [element];
      const confidences = this.getFormAutofillConfidences(elements);

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
  },

  /**
   * @param {Array} elements Array of elements that we want to get result from fathom cc rules
   * @returns {object} Fathom confidence keyed by field-type.
   */
  getFormAutofillConfidences(elements) {
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
  },

  /**
   * @typedef ElementStrings
   * @type {object}
   * @yields {string} id - element id.
   * @yields {string} name - element name.
   * @yields {Array<string>} labels - extracted labels.
   */

  /**
   * Extract all the signature strings of an element.
   *
   * @param {HTMLElement} element
   * @returns {Array<string>}
   */
  _getElementStrings(element) {
    return [element.id, element.name, element.placeholder?.trim()];
  },

  /**
   * Extract all the label strings associated with an element.
   *
   * @param {HTMLElement} element
   * @returns {ElementStrings}
   */
  _getElementLabelStrings(element) {
    return {
      *[Symbol.iterator]() {
        const labels = lazy.LabelUtils.findLabelElements(element);
        for (let label of labels) {
          yield* lazy.LabelUtils.extractLabelStrings(label);
        }

        const ariaLabels = element.getAttribute("aria-label");
        if (ariaLabels) {
          yield* [ariaLabels];
        }
      },
    };
  },

  // In order to support webkit we need to avoid usage of negative lookbehind due to low support
  // First safari version with support is 16.4 (Release Date: 27th March 2023)
  // https://caniuse.com/js-regexp-lookbehind
  // We can mimic the behaviour of negative lookbehinds by using a named capture group
  // (?<!not)word -> (?<neg>notword)|word
  // TODO: Bug 1829583
  testRegex(regex, string) {
    const matches = string?.matchAll(regex);
    if (!matches) {
      return false;
    }

    const excludeNegativeCaptureGroups = [];

    for (const match of matches) {
      excludeNegativeCaptureGroups.push(
        ...match.filter(m => m !== match?.groups?.neg).filter(Boolean)
      );
    }
    return excludeNegativeCaptureGroups?.length > 0;
  },

  /**
   * Find the first matching field name from a given list of field names
   * that matches an HTML element.
   *
   * The function first tries to match the element against a set of
   * pre-defined regular expression rules. If no match is found, it
   * then checks for label-specific rules, if they exist.
   *
   * Note: For label rules, the keyword is often more general
   * (e.g., "^\\W*address"), hence they are only searched within labels
   * to reduce the occurrence of false positives.
   *
   * @param {HTMLElement} element The element to match.
   * @param {Array<string>} fieldNames An array of field names to compare against.
   * @returns {string|null} The name of the matched field, or null if no match was found.
   */
  _findMatchedFieldName(element, fieldNames) {
    if (!fieldNames.length) {
      return null;
    }

    // Attempt to match the element against the default set of rules
    let matchedFieldName = fieldNames.find(fieldName =>
      this._matchRegexp(element, this.RULES[fieldName])
    );

    // If no match is found, and if a label rule exists for the field,
    // attempt to match against the label rules
    if (!matchedFieldName) {
      matchedFieldName = fieldNames.find(fieldName => {
        const regexp = this.LABEL_RULES[fieldName];
        return this._matchRegexp(element, regexp, { attribute: false });
      });
    }
    return matchedFieldName;
  },

  /**
   * Determine whether the regexp can match any of element strings.
   *
   * @param {HTMLElement} element The HTML element to match.
   * @param {RegExp} regexp       The regular expression to match against.
   * @param {object} [options]    Optional parameters for matching.
   * @param {boolean} [options.attribute=true]
   *                              Whether to match against the element's attributes.
   * @param {boolean} [options.label=true]
   *                              Whether to match against the element's labels.
   * @returns {boolean} True if a match is found, otherwise false.
   */
  _matchRegexp(element, regexp, { attribute = true, label = true } = {}) {
    if (!regexp) {
      return false;
    }

    if (attribute) {
      const elemStrings = this._getElementStrings(element);
      if (elemStrings.find(s => this.testRegex(regexp, s?.toLowerCase()))) {
        return true;
      }
    }

    if (label) {
      const elementLabelStrings = this._getElementLabelStrings(element);
      for (const s of elementLabelStrings) {
        if (this.testRegex(regexp, s?.toLowerCase())) {
          return true;
        }
      }
    }

    return false;
  },

  /**
   * Phone field grammars - first matched grammar will be parsed. Grammars are
   * separated by { REGEX_SEPARATOR, FIELD_NONE, 0 }. Suffix and extension are
   * parsed separately unless they are necessary parts of the match.
   * The following notation is used to describe the patterns:
   * <cc> - country code field.
   * <ac> - area code field.
   * <phone> - phone or prefix.
   * <suffix> - suffix.
   * <ext> - extension.
   * :N means field is limited to N characters, otherwise it is unlimited.
   * (pattern <field>)? means pattern is optional and matched separately.
   *
   * This grammar list from Chromium will be enabled partially once we need to
   * support more cases of Telephone fields.
   */
  PHONE_FIELD_GRAMMARS: [
    // Country code: <cc> Area Code: <ac> Phone: <phone> (- <suffix>

    // (Ext: <ext>)?)?
    // {REGEX_COUNTRY, FIELD_COUNTRY_CODE, 0},
    // {REGEX_AREA, FIELD_AREA_CODE, 0},
    // {REGEX_PHONE, FIELD_PHONE, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // \( <ac> \) <phone>:3 <suffix>:4 (Ext: <ext>)?
    // {REGEX_AREA_NOTEXT, FIELD_AREA_CODE, 3},
    // {REGEX_PREFIX_SEPARATOR, FIELD_PHONE, 3},
    // {REGEX_PHONE, FIELD_SUFFIX, 4},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <cc> <ac>:3 - <phone>:3 - <suffix>:4 (Ext: <ext>)?
    // {REGEX_PHONE, FIELD_COUNTRY_CODE, 0},
    // {REGEX_PHONE, FIELD_AREA_CODE, 3},
    // {REGEX_PREFIX_SEPARATOR, FIELD_PHONE, 3},
    // {REGEX_SUFFIX_SEPARATOR, FIELD_SUFFIX, 4},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <cc>:3 <ac>:3 <phone>:3 <suffix>:4 (Ext: <ext>)?
    ["tel", "tel-country-code", 3],
    ["tel", "tel-area-code", 3],
    ["tel", "tel-local-prefix", 3],
    ["tel", "tel-local-suffix", 4],
    [null, null, 0],

    // Area Code: <ac> Phone: <phone> (- <suffix> (Ext: <ext>)?)?
    // {REGEX_AREA, FIELD_AREA_CODE, 0},
    // {REGEX_PHONE, FIELD_PHONE, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <ac> <phone>:3 <suffix>:4 (Ext: <ext>)?
    // {REGEX_PHONE, FIELD_AREA_CODE, 0},
    // {REGEX_PHONE, FIELD_PHONE, 3},
    // {REGEX_PHONE, FIELD_SUFFIX, 4},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <cc> \( <ac> \) <phone> (- <suffix> (Ext: <ext>)?)?
    // {REGEX_PHONE, FIELD_COUNTRY_CODE, 0},
    // {REGEX_AREA_NOTEXT, FIELD_AREA_CODE, 0},
    // {REGEX_PREFIX_SEPARATOR, FIELD_PHONE, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: \( <ac> \) <phone> (- <suffix> (Ext: <ext>)?)?
    // {REGEX_PHONE, FIELD_COUNTRY_CODE, 0},
    // {REGEX_AREA_NOTEXT, FIELD_AREA_CODE, 0},
    // {REGEX_PREFIX_SEPARATOR, FIELD_PHONE, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <cc> - <ac> - <phone> - <suffix> (Ext: <ext>)?
    // {REGEX_PHONE, FIELD_COUNTRY_CODE, 0},
    // {REGEX_PREFIX_SEPARATOR, FIELD_AREA_CODE, 0},
    // {REGEX_PREFIX_SEPARATOR, FIELD_PHONE, 0},
    // {REGEX_SUFFIX_SEPARATOR, FIELD_SUFFIX, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Area code: <ac>:3 Prefix: <prefix>:3 Suffix: <suffix>:4 (Ext: <ext>)?
    // {REGEX_AREA, FIELD_AREA_CODE, 3},
    // {REGEX_PREFIX, FIELD_PHONE, 3},
    // {REGEX_SUFFIX, FIELD_SUFFIX, 4},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <ac> Prefix: <phone> Suffix: <suffix> (Ext: <ext>)?
    // {REGEX_PHONE, FIELD_AREA_CODE, 0},
    // {REGEX_PREFIX, FIELD_PHONE, 0},
    // {REGEX_SUFFIX, FIELD_SUFFIX, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <ac> - <phone>:3 - <suffix>:4 (Ext: <ext>)?
    ["tel", "tel-area-code", 0],
    ["tel", "tel-local-prefix", 3],
    ["tel", "tel-local-suffix", 4],
    [null, null, 0],

    // Phone: <cc> - <ac> - <phone> (Ext: <ext>)?
    // {REGEX_PHONE, FIELD_COUNTRY_CODE, 0},
    // {REGEX_PREFIX_SEPARATOR, FIELD_AREA_CODE, 0},
    // {REGEX_SUFFIX_SEPARATOR, FIELD_PHONE, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <ac> - <phone> (Ext: <ext>)?
    // {REGEX_AREA, FIELD_AREA_CODE, 0},
    // {REGEX_PHONE, FIELD_PHONE, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <cc>:3 - <phone>:10 (Ext: <ext>)?
    // {REGEX_PHONE, FIELD_COUNTRY_CODE, 3},
    // {REGEX_PHONE, FIELD_PHONE, 10},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Ext: <ext>
    // {REGEX_EXTENSION, FIELD_EXTENSION, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},

    // Phone: <phone> (Ext: <ext>)?
    // {REGEX_PHONE, FIELD_PHONE, 0},
    // {REGEX_SEPARATOR, FIELD_NONE, 0},
  ],
};

ChromeUtils.defineLazyGetter(
  FormAutofillHeuristics,
  "CREDIT_CARD_FIELDNAMES",
  () =>
    Object.keys(FormAutofillHeuristics.RULES).filter(name =>
      lazy.FormAutofillUtils.isCreditCardField(name)
    )
);

ChromeUtils.defineLazyGetter(FormAutofillHeuristics, "ADDRESS_FIELDNAMES", () =>
  Object.keys(FormAutofillHeuristics.RULES).filter(name =>
    lazy.FormAutofillUtils.isAddressField(name)
  )
);

export default FormAutofillHeuristics;
