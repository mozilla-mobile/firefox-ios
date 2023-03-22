import { FormAutofillUtilsShared } from "resource://gre/modules/FormAutofillUtils.shared.mjs";
import { CreditCard } from "resource://gre/modules/CreditCard.sys.mjs";
import { LabelUtils } from "resource://gre/modules/LabelUtils.mjs";
import { FieldScanner } from "resource://gre/modules/FieldScanner.mjs";
import { creditCardRulesets } from "resource://gre/modules/CreditCardRuleset.mjs";

// TODO(HACK): Update this
// const creditCardRulesets = {
//   types: ["cc-number", "cc-name"],
// };

/**
 * Returns the autocomplete information of fields according to heuristics.
 */
export const FormAutofillHeuristicsShared = {
  // TODO(HACK): Update this
  RULES: {
    "cc-name":
      /(accountholdername|titulaire)|(cc-?name|card-?name|cardholder-?name|cardholder|(^nom$))|(card.?(?:holder|owner)|name.*(\b)?on(\b)?.*card|(?:card|cc).?name|cc.?full.?name|karteninhaber|nombre.*tarjeta|nom.*carte|nome.*cart|名前|имя.*карты|信用卡开户名|开户名|持卡人姓名|持卡人姓名)/u,
    // TODO(HACK): This was updated to not use lookahead or lookbehind
    // ( because of lack of support in webkit ), Revisit this
    "cc-number":
      /(cc|kk)nr|(cc-?number|cc-?num|card-?number|card-?num|number|cc|cc-?no|card-?no|credit-?card|numero-?carte|carte|carte-?credit|num-?carte|cb-?num)|((add)?(card|cc|acct)[\s#]*)(number|no|num|field)|((telefon|haus|person|fødsels)?nummer[^\s]*|nummer[^\s]*|カード番号|номер.*карты|信用卡号(?:码|卡號)?|카드|(numero|número|numéro))(?:(?:document|fono|phone|réservation)\b|$)/u,
    "cc-exp-month":
      /(month|(cc|kk)month)|((^exp-?month$)|(^cc-?exp-?month$)|(^cc-?month$)|(^card-?month$)|(^cc-?mo$)|(^card-?mo$)|(^exp-?mo$)|(^card-?exp-?mo$)|(^cc-?exp-?mo$)|(^card-?expiration-?month$)|(^expiration-?month$)|(^cc-?mm$)|(^cc-?m$)|(^card-?mm$)|(^card-?m$)|(^card-?exp-?mm$)|(^cc-?exp-?mm$)|(^exp-?mm$)|(^exp-?m$)|(^expire-?month$)|(^expire-?mo$)|(^expiry-?month$)|(^expiry-?mo$)|(^card-?expire-?month$)|(^card-?expire-?mo$)|(^card-?expiry-?month$)|(^card-?expiry-?mo$)|(^mois-?validite$)|(^mois-?expiration$)|(^m-?validite$)|(^m-?expiration$)|(^expiry-?date-?field-?month$)|(^expiration-?date-?month$)|(^expiration-?date-?mm$)|(^exp-?mon$)|(^validity-?mo$)|(^exp-?date-?mo$)|(^cb-?date-?mois$)|(^date-?m$))|(expir|exp.*mo|exp.*date|ccmonth|cardmonth|addmonth|gueltig|gültig|monat|fecha|date.*exp|scadenza|有効期限|validade|срок действия карты|月)/u,
    "cc-exp-year":
      /(year|(cc|kk)year)|((^exp-?year$)|(^cc-?exp-?year$)|(^cc-?year$)|(^card-?year$)|(^cc-?yr$)|(^card-?yr$)|(^exp-?yr$)|(^card-?exp-?yr$)|(^cc-?exp-?yr$)|(^card-?expiration-?year$)|(^expiration-?year$)|(^cc-?yy$)|(^cc-?y$)|(^card-?yy$)|(^card-?y$)|(^card-?exp-?yy$)|(^cc-?exp-?yy$)|(^exp-?yy$)|(^exp-?y$)|(^cc-?yyyy$)|(^card-?yyyy$)|(^card-?exp-?yyyy$)|(^cc-?exp-?yyyy$)|(^expire-?year$)|(^expire-?yr$)|(^expiry-?year$)|(^expiry-?yr$)|(^card-?expire-?year$)|(^card-?expire-?yr$)|(^card-?expiry-?year$)|(^card-?expiry-?yr$)|(^an-?validite$)|(^an-?expiration$)|(^annee-?validite$)|(^annee-?expiration$)|(^expiry-?date-?field-?year$)|(^expiration-?date-?year$)|(^cb-?date-?ann$)|(^expiration-?date-?yy$)|(^expiration-?date-?yyyy$)|(^validity-?year$)|(^exp-?date-?year$)|(^date-?y$))|(exp|^\/|(add)?year|ablaufdatum|gueltig|gültig|jahr|fecha|scadenza|有効期限|validade|срок действия карты|年|有效期)/u,
    "cc-exp":
      /((^cc-?exp$)|(^card-?exp$)|(^cc-?expiration$)|(^card-?expiration$)|(^cc-?ex$)|(^card-?ex$)|(^card-?expire$)|(^card-?expiry$)|(^validite$)|(^expiration$)|(^expiry$)|mm-?yy|mm-?yyyy|yy-?mm|yyyy-?mm|expiration-?date|payment-?card-?expiration|(^payment-?cc-?date$))|(expir|exp.*date|^expfield$|gueltig|gültig|fecha|date.*exp|scadenza|有効期限|validade|срок действия карты)/u,
    "cc-type":
      /(type|kartenmarke)|((^cc-?type$)|(^card-?type$)|(^card-?brand$)|(^cc-?brand$)|(^cb-?type$))/u,
  },
  // TODO(HACK): Update this
  CREDIT_CARD_FIELDNAMES: [
    "cc-name",
    "cc-number",
    "cc-exp-month",
    "cc-exp-year",
    "cc-exp",
    "cc-type",
  ],
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
        options.map((e) => +e.value),
        desiredValues
      ) ||
      this._matchContiguousSubArray(
        options.map((e) => +e.label),
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
        options.map((e) => +e.value),
        desiredValues
      ) ||
      this._matchContiguousSubArray(
        options.map((e) => +e.label),
        desiredValues
      )
    );
  },

  /**
   * Try to match the telephone related fields to the grammar
   * list to see if there is any valid telephone set and correct their
   * field names.
   *
   * @param {FieldScanner} fieldScanner
   *        The current parsing status for all elements
   * @returns {boolean}
   *          Return true if there is any field can be recognized in the parser,
   *          otherwise false.
   */
  _parsePhoneFields(fieldScanner) {
    let matchingResult;

    const GRAMMARS = this.PHONE_FIELD_GRAMMARS;
    for (let i = 0; i < GRAMMARS.length; i++) {
      let detailStart = fieldScanner.parsingIndex;
      let ruleStart = i;
      for (
        ;
        i < GRAMMARS.length &&
        GRAMMARS[i][0] &&
        fieldScanner.elementExisting(detailStart);
        i++, detailStart++
      ) {
        let detail = fieldScanner.getFieldDetailByIndex(detailStart);
        if (
          !detail ||
          GRAMMARS[i][0] != detail.fieldName ||
          (detail._reason && detail._reason == "autocomplete")
        ) {
          break;
        }
        let element = detail.elementWeakRef.get();
        if (!element) {
          break;
        }
        if (
          GRAMMARS[i][2] &&
          (!element.maxLength || GRAMMARS[i][2] < element.maxLength)
        ) {
          break;
        }
      }
      if (i >= GRAMMARS.length) {
        break;
      }

      if (!GRAMMARS[i][0]) {
        matchingResult = {
          ruleFrom: ruleStart,
          ruleTo: i,
        };
        break;
      }

      // Fast rewinding to the next rule.
      for (; i < GRAMMARS.length; i++) {
        if (!GRAMMARS[i][0]) {
          break;
        }
      }
    }

    let parsedField = false;
    if (matchingResult) {
      let { ruleFrom, ruleTo } = matchingResult;
      let detailStart = fieldScanner.parsingIndex;
      for (let i = ruleFrom; i < ruleTo; i++) {
        fieldScanner.updateFieldName(detailStart, GRAMMARS[i][1]);
        fieldScanner.parsingIndex++;
        detailStart++;
        parsedField = true;
      }
    }

    if (fieldScanner.parsingFinished) {
      return parsedField;
    }

    let nextField = fieldScanner.getFieldDetailByIndex(
      fieldScanner.parsingIndex
    );
    if (
      nextField &&
      nextField._reason != "autocomplete" &&
      fieldScanner.parsingIndex > 0
    ) {
      const regExpTelExtension = new RegExp(
        "\\bext|ext\\b|extension|ramal", // pt-BR, pt-PT
        "iu"
      );
      const previousField = fieldScanner.getFieldDetailByIndex(
        fieldScanner.parsingIndex - 1
      );
      const previousFieldType =
        FormAutofillUtilsShared.getCategoryFromFieldName(
          previousField.fieldName
        );
      if (
        previousField &&
        previousFieldType == "tel" &&
        this._matchRegexp(nextField.elementWeakRef.get(), regExpTelExtension)
      ) {
        fieldScanner.updateFieldName(
          fieldScanner.parsingIndex,
          "tel-extension"
        );
        fieldScanner.parsingIndex++;
        parsedField = true;
      }
    }

    return parsedField;
  },

  /**
   * Try to find the correct address-line[1-3] sequence and correct their field
   * names.
   *
   * @param {FieldScanner} fieldScanner
   *        The current parsing status for all elements
   * @returns {boolean}
   *          Return true if there is any field can be recognized in the parser,
   *          otherwise false.
   */
  _parseAddressFields(fieldScanner) {
    let parsedFields = false;
    const addressLines = ["address-line1", "address-line2", "address-line3"];

    // TODO: These address-line* regexps are for the lines with numbers, and
    // they are the subset of the regexps in `heuristicsRegexp.js`. We have to
    // find a better way to make them consistent.
    const addressLineRegexps = {
      "address-line1": new RegExp(
        "address[_-]?line(1|one)|address1|addr1" +
          "|addrline1|address_1" + // Extra rules by Firefox
          "|indirizzo1" + // it-IT
          "|住所1" + // ja-JP
          "|地址1" + // zh-CN
          "|주소.?1", // ko-KR
        "iu"
      ),
      "address-line2": new RegExp(
        "address[_-]?line(2|two)|address2|addr2" +
          "|addrline2|address_2" + // Extra rules by Firefox
          "|indirizzo2" + // it-IT
          "|住所2" + // ja-JP
          "|地址2" + // zh-CN
          "|주소.?2", // ko-KR
        "iu"
      ),
      "address-line3": new RegExp(
        "address[_-]?line(3|three)|address3|addr3" +
          "|addrline3|address_3" + // Extra rules by Firefox
          "|indirizzo3" + // it-IT
          "|住所3" + // ja-JP
          "|地址3" + // zh-CN
          "|주소.?3", // ko-KR
        "iu"
      ),
    };
    while (!fieldScanner.parsingFinished) {
      let detail = fieldScanner.getFieldDetailByIndex(
        fieldScanner.parsingIndex
      );
      if (
        !detail ||
        !addressLines.includes(detail.fieldName) ||
        detail._reason == "autocomplete"
      ) {
        // When the field is not related to any address-line[1-3] fields or
        // determined by autocomplete attr, it means the parsing process can be
        // terminated.
        break;
      }
      const elem = detail.elementWeakRef.get();
      for (let regexp of Object.keys(addressLineRegexps)) {
        if (this._matchRegexp(elem, addressLineRegexps[regexp])) {
          fieldScanner.updateFieldName(fieldScanner.parsingIndex, regexp);
          parsedFields = true;
        }
      }
      fieldScanner.parsingIndex++;
    }

    return parsedFields;
  },

  // The old heuristics can be removed when we fully adopt fathom, so disable the
  // esline complexity check for now
  /* eslint-disable complexity */
  /**
   * Try to look for expiration date fields and revise the field names if needed.
   *
   * @param {FieldScanner} fieldScanner
   *        The current parsing status for all elements
   * @returns {boolean}
   *          Return true if there is any field can be recognized in the parser,
   *          otherwise false.
   */
  _parseCreditCardFields(fieldScanner) {
    if (fieldScanner.parsingFinished) {
      return false;
    }

    const savedIndex = fieldScanner.parsingIndex;
    const detail = fieldScanner.getFieldDetailByIndex(
      fieldScanner.parsingIndex
    );

    // Respect to autocomplete attr
    if (!detail || (detail._reason && detail._reason == "autocomplete")) {
      return false;
    }

    const monthAndYearFieldNames = ["cc-exp-month", "cc-exp-year"];
    // Skip the uninteresting fields
    if (
      !["cc-exp", "cc-type", ...monthAndYearFieldNames].includes(
        detail.fieldName
      )
    ) {
      return false;
    }

    // The heuristic below should be covered by fathom rules, so we can skip doing
    // it.
    if (
      FormAutofillUtilsShared.isFathomCreditCardsEnabled() &&
      creditCardRulesets.types.includes(detail.fieldName)
    ) {
      fieldScanner.parsingIndex++;
      return true;
    }

    const element = detail.elementWeakRef.get();

    // If we didn't auto-discover type field, check every select for options that
    // match credit card network names in value or label.
    if (HTMLSelectElement.isInstance(element)) {
      for (let option of element.querySelectorAll("option")) {
        if (
          CreditCard.getNetworkFromName(option.value) ||
          CreditCard.getNetworkFromName(option.text)
        ) {
          fieldScanner.updateFieldName(fieldScanner.parsingIndex, "cc-type");
          fieldScanner.parsingIndex++;
          return true;
        }
      }
    }

    // If the input type is a month picker, then assume it's cc-exp.
    if (element.type == "month") {
      fieldScanner.updateFieldName(fieldScanner.parsingIndex, "cc-exp");
      fieldScanner.parsingIndex++;

      return true;
    }

    // Don't process the fields if expiration month and expiration year are already
    // matched by regex in correct order.
    if (
      fieldScanner.getFieldDetailByIndex(fieldScanner.parsingIndex++)
        .fieldName == "cc-exp-month" &&
      !fieldScanner.parsingFinished &&
      fieldScanner.getFieldDetailByIndex(fieldScanner.parsingIndex++)
        .fieldName == "cc-exp-year"
    ) {
      return true;
    }
    fieldScanner.parsingIndex = savedIndex;

    // Determine the field name by checking if the fields are month select and year select
    // likely.
    if (this._isExpirationMonthLikely(element)) {
      fieldScanner.updateFieldName(fieldScanner.parsingIndex, "cc-exp-month");
      fieldScanner.parsingIndex++;
      if (!fieldScanner.parsingFinished) {
        const nextDetail = fieldScanner.getFieldDetailByIndex(
          fieldScanner.parsingIndex
        );
        const nextElement = nextDetail.elementWeakRef.get();
        if (this._isExpirationYearLikely(nextElement)) {
          fieldScanner.updateFieldName(
            fieldScanner.parsingIndex,
            "cc-exp-year"
          );
          fieldScanner.parsingIndex++;
          return true;
        }
      }
    }
    fieldScanner.parsingIndex = savedIndex;

    // Verify that the following consecutive two fields can match cc-exp-month and cc-exp-year
    // respectively.
    if (this._findMatchedFieldName(element, ["cc-exp-month"])) {
      fieldScanner.updateFieldName(fieldScanner.parsingIndex, "cc-exp-month");
      fieldScanner.parsingIndex++;
      if (!fieldScanner.parsingFinished) {
        const nextDetail = fieldScanner.getFieldDetailByIndex(
          fieldScanner.parsingIndex
        );
        const nextElement = nextDetail.elementWeakRef.get();
        if (this._findMatchedFieldName(nextElement, ["cc-exp-year"])) {
          fieldScanner.updateFieldName(
            fieldScanner.parsingIndex,
            "cc-exp-year"
          );
          fieldScanner.parsingIndex++;
          return true;
        }
      }
    }
    fieldScanner.parsingIndex = savedIndex;

    // Look for MM and/or YY(YY).
    if (this._matchRegexp(element, /^mm$/gi)) {
      fieldScanner.updateFieldName(fieldScanner.parsingIndex, "cc-exp-month");
      fieldScanner.parsingIndex++;
      if (!fieldScanner.parsingFinished) {
        const nextDetail = fieldScanner.getFieldDetailByIndex(
          fieldScanner.parsingIndex
        );
        const nextElement = nextDetail.elementWeakRef.get();
        if (this._matchRegexp(nextElement, /^(yy|yyyy)$/)) {
          fieldScanner.updateFieldName(
            fieldScanner.parsingIndex,
            "cc-exp-year"
          );
          fieldScanner.parsingIndex++;

          return true;
        }
      }
    }
    fieldScanner.parsingIndex = savedIndex;

    // Look for a cc-exp with 2-digit or 4-digit year.
    if (
      this._matchRegexp(
        element,
        /(?:exp.*date[^y\\n\\r]*|mm\\s*[-/]?\\s*)yy(?:[^y]|$)/gi
      ) ||
      this._matchRegexp(
        element,
        /(?:exp.*date[^y\\n\\r]*|mm\\s*[-/]?\\s*)yyyy(?:[^y]|$)/gi
      )
    ) {
      fieldScanner.updateFieldName(fieldScanner.parsingIndex, "cc-exp");
      fieldScanner.parsingIndex++;
      return true;
    }
    fieldScanner.parsingIndex = savedIndex;

    // Match general cc-exp regexp at last.
    if (this._findMatchedFieldName(element, ["cc-exp"])) {
      fieldScanner.updateFieldName(fieldScanner.parsingIndex, "cc-exp");
      fieldScanner.parsingIndex++;
      return true;
    }
    fieldScanner.parsingIndex = savedIndex;

    // Set current field name to null as it failed to match any patterns.
    fieldScanner.updateFieldName(fieldScanner.parsingIndex, null);
    fieldScanner.parsingIndex++;
    return true;
  },

  /**
   * This function should provide all field details of a form which are placed
   * in the belonging section. The details contain the autocomplete info
   * (e.g. fieldName, section, etc).
   *
   * `allowDuplicates` is used for the xpcshell-test purpose currently because
   * the heuristics should be verified that some duplicated elements still can
   * be predicted correctly.
   *
   * @param {HTMLFormElement} form
   *        the elements in this form to be predicted the field info.
   * @param {boolean} allowDuplicates
   *        true to remain any duplicated field details otherwise to remove the
   *        duplicated ones.
   * @returns {Array<Array<object>>}
   *        all sections within its field details in the form.
   */
  getFormInfo(form, allowDuplicates = false) {
    const eligibleFields = Array.from(form.elements).filter((elem) =>
      FormAutofillUtilsShared.isCreditCardOrAddressFieldType(elem)
    );

    if (eligibleFields.length <= 0) {
      return [];
    }

    let fieldScanner = new FieldScanner(eligibleFields, {
      allowDuplicates,
      sectionEnabled: this._sectionEnabled,
    });
    while (!fieldScanner.parsingFinished) {
      let parsedPhoneFields = this._parsePhoneFields(fieldScanner);
      let parsedAddressFields = this._parseAddressFields(fieldScanner);
      let parsedExpirationDateFields =
        this._parseCreditCardFields(fieldScanner);

      // If there is no field parsed, the parsing cursor can be moved
      // forward to the next one.
      if (
        !parsedPhoneFields &&
        !parsedAddressFields &&
        !parsedExpirationDateFields
      ) {
        fieldScanner.parsingIndex++;
      }
    }

    LabelUtils.clearLabelMap();
    return fieldScanner.getSectionFieldDetails();
  },

  _getPossibleFieldNames(element) {
    let fieldNames = [];
    let isAutoCompleteOff =
      element.autocomplete == "off" || element.form?.autocomplete == "off";
    //TODO(HACK): Update this
    // if (
    //   FormAutofill.isAutofillCreditCardsAvailable &&
    //   (!isAutoCompleteOff || FormAutofill.creditCardsAutocompleteOff)
    // ) {
    //   fieldNames.push(...this.CREDIT_CARD_FIELDNAMES);
    // }
    fieldNames.push(...this.CREDIT_CARD_FIELDNAMES);

    //TODO(HACK): Update this
    // if (
    //     FormAutofill.isAutofillAddressesAvailable &&
    //     (!isAutoCompleteOff || FormAutofill.addressesAutocompleteOff)
    //   )
    // if (!isAutoCompleteOff) {
    //   fieldNames.push(...this.ADDRESS_FIELDNAMES);
    // }

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
      fieldNames = fieldNames.filter((name) =>
        FIELDNAMES_FOR_SELECT_ELEMENT.includes(name)
      );
    }

    return fieldNames;
  },

  getInfo(element, scanner) {
    function infoRecordWithFieldName(fieldName, confidence = null) {
      return {
        fieldName,
        section: "",
        addressType: "",
        contactType: "",
        confidence,
      };
    }

    let info = element.getAutocompleteInfo();

    // An input[autocomplete="on"] will not be early return here since it stll
    // needs to find the field name.
    if (
      info &&
      info.fieldName &&
      info.fieldName != "on" &&
      info.fieldName != "off"
    ) {
      info._reason = "autocomplete";
      return info;
    }

    // TODO(HACK): Update this
    // if (!this._prefEnabled) {
    //   return null;
    // }

    let fields = this._getPossibleFieldNames(element);

    // "email" type of input is accurate for heuristics to determine its Email
    // field or not. However, "tel" type is used for ZIP code for some web site
    // (e.g. HomeDepot, BestBuy), so "tel" type should be not used for "tel"
    // prediction.
    if (element.type == "email" && fields.includes("email")) {
      return infoRecordWithFieldName("email");
    }

    if (FormAutofillUtilsShared.isFathomCreditCardsEnabled()) {
      // We don't care fields that are not supported by fathom
      let fathomFields = fields.filter((r) =>
        creditCardRulesets.types.includes(r)
      );
      let [matchedFieldName, confidence] = scanner.getFathomField(
        element,
        fathomFields
      );
      // At this point, use fathom's recommendation if it has one
      if (matchedFieldName) {
        return infoRecordWithFieldName(matchedFieldName, confidence);
      }

      // Continue to run regex-based heuristics even when fathom doesn't recognize
      // the field. Since the regex-based heuristic has good search coverage but
      // has a worse precision. We use it in conjunction with fathom to maximize
      // our search coverage. For example, when a <input> is not considered cc-name
      // by fathom but is considered cc-name by regex-based heuristic, if the form
      // also contains a cc-number identified by fathom, we will treat the form as a
      // valid cc form; hence both cc-number & cc-name are identified.
    }

    if (fields.length) {
      let matchedFieldName = this._findMatchedFieldName(element, fields);
      if (matchedFieldName) {
        return infoRecordWithFieldName(matchedFieldName);
      }
    }

    return null;
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
   * @returns {ElementStrings}
   */
  _getElementStrings(element) {
    return {
      *[Symbol.iterator]() {
        yield element.id;
        yield element.name;
        yield element.placeholder?.trim();

        const labels = LabelUtils.findLabelElements(element);
        for (let label of labels) {
          yield* LabelUtils.extractLabelStrings(label);
        }
      },
    };
  },

  /**
   * Find the first matched field name of the element wih given regex list.
   *
   * @param {HTMLElement} element
   * @param {Array<string>} regexps
   *        The regex key names that correspond to pattern in the rule list. It will
   *        be matched against the element string converted to lower case.
   * @returns {?string} The first matched field name
   */
  _findMatchedFieldName(element, regexps) {
    const getElementStrings = this._getElementStrings(element);
    for (let regexp of regexps) {
      for (let string of getElementStrings) {
        if (this.RULES[regexp].test(string?.toLowerCase())) {
          return regexp;
        }
      }
    }

    return null;
  },

  /**
   * Determine whether the regexp can match any of element strings.
   *
   * @param {HTMLElement} element
   * @param {RegExp} regexp
   *
   * @returns {boolean}
   */
  _matchRegexp(element, regexp) {
    const elemStrings = this._getElementStrings(element);
    for (const str of elemStrings) {
      if (regexp.test(str)) {
        return true;
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
