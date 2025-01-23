/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Fathom ML model for identifying the fields of credit-card forms
 *
 * This is developed out-of-tree at https://github.com/mozilla-services/fathom-
 * form-autofill, where there is also over a GB of training, validation, and
 * testing data. To make changes, do your edits there (whether adding new
 * training pages, adding new rules, or both), retrain and evaluate as
 * documented at https://mozilla.github.io/fathom/training.html, paste the
 * coefficients emitted by the trainer into the ruleset, and finally copy the
 * ruleset's "CODE TO COPY INTO PRODUCTION" section to this file's "CODE FROM
 * TRAINING REPOSITORY" section.
 */

/**
 * CODE UNIQUE TO PRODUCTION--NOT IN THE TRAINING REPOSITORY:
 */

import {
  element as clickedElement,
  out,
  rule,
  ruleset,
  score,
  type,
} from "resource://gre/modules/third_party/fathom/fathom.mjs";
import { XPCOMUtils } from "resource://gre/modules/XPCOMUtils.sys.mjs";
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import {
  CreditCard,
  NETWORK_NAMES,
} from "resource://gre/modules/CreditCard.sys.mjs";

import { FormLikeFactory } from "resource://gre/modules/FormLikeFactory.sys.mjs";
import { LabelUtils } from "resource://gre/modules/shared/LabelUtils.sys.mjs";

/**
 * Callthrough abstraction to allow .getAutocompleteInfo() to be mocked out
 * during training
 *
 * @param {Element} element DOM element to get info about
 * @returns {object} Page-author-provided autocomplete metadata
 */
function getAutocompleteInfo(element) {
  return element.getAutocompleteInfo();
}

/**
 * @param {string} selector A CSS selector that prunes away ineligible elements
 * @returns {Lhs} An LHS yielding the element the user has clicked or, if
 *  pruned, none
 */
function queriedOrClickedElements(selector) {
  return clickedElement(selector);
}

/**
 * START OF CODE PASTED FROM TRAINING REPOSITORY
 */

var FathomHeuristicsRegExp = {
  RULES: {
    "cc-name": undefined,
    "cc-number": undefined,
    "cc-exp-month": undefined,
    "cc-exp-year": undefined,
    "cc-exp": undefined,
    "cc-type": undefined,
  },

  RULE_SETS: [
    {
      /* eslint-disable */
      // Let us keep our consistent wrapping.
      "cc-name":
        // Firefox-specific rules
        "account.*holder.*name" +
        "|^(credit[-\\s]?card|card).*name" +
        // de-DE
        "|^(kredit)?(karten|konto)inhaber" +
        "|^(name).*karte" +
        // fr-FR
        "|nom.*(titulaire|détenteur)" +
        "|(titulaire|détenteur).*(carte)" +
        // it-IT
        "|titolare.*carta" +
        // pl-PL
        "|posiadacz.*karty" +
        // es-ES
        "|nombre.*(titular|tarjeta)" +
        // nl-NL
        "|naam.*op.*kaart" +
        // Rules from Bitwarden
        "|cc-?name" +
        "|card-?name" +
        "|cardholder-?name" +
        "|(^nom$)" +
        // Rules are from Chromium source codes
        "|card.?(?:holder|owner)|name.*(\\b)?on(\\b)?.*card" +
        "|(?:card|cc).?name|cc.?full.?name" +
        "|(?:card|cc).?owner" +
        "|nom.*carte" + // fr-FR
        "|nome.*cart" + // it-IT
        "|名前" + // ja-JP
        "|Имя.*карты" + // ru
        "|信用卡开户名|开户名|持卡人姓名" + // zh-CN
        "|持卡人姓名", // zh-TW

      "cc-number":
        // Firefox-specific rules
        // de-DE
        "(cc|kk)nr" +
        "|(kredit)?(karten)(nummer|nr)" +
        // it-IT
        "|numero.*carta" +
        // fr-FR
        "|(numero|número|numéro).*(carte)" +
        // pl-PL
        "|numer.*karty" +
        // es-ES
        "|(número|numero).*tarjeta" +
        // nl-NL
        "|kaartnummer" +
        // Rules from Bitwarden
        "|cc-?number" +
        "|cc-?num" +
        "|card-?number" +
        "|card-?num" +
        "|cc-?no" +
        "|card-?no" +
        "|numero-?carte" +
        "|num-?carte" +
        "|cb-?num" +
        // Rules are from Chromium source codes
        "|(add)?(?:card|cc|acct).?(?:number|#|no|num)" +
        "|カード番号" + // ja-JP
        "|Номер.*карты" + // ru
        "|信用卡号|信用卡号码" + // zh-CN
        "|信用卡卡號" + // zh-TW
        "|카드", // ko-KR

      "cc-exp":
        // Firefox-specific rules
        "mm\\s*(\/|\\|-)\\s*(yy|jj|aa)" +
        "|(month|mois)\\s*(\/|\\|-|et)\\s*(year|année)" +
        // de-DE
        // fr-FR
        // Rules from Bitwarden
        "|(^cc-?exp$)" +
        "|(^card-?exp$)" +
        "|(^cc-?expiration$)" +
        "|(^card-?expiration$)" +
        "|(^cc-?ex$)" +
        "|(^card-?ex$)" +
        "|(^card-?expire$)" +
        "|(^card-?expiry$)" +
        "|(^validite$)" +
        "|(^expiration$)" +
        "|(^expiry$)" +
        "|mm-?yy" +
        "|mm-?yyyy" +
        "|yy-?mm" +
        "|yyyy-?mm" +
        "|expiration-?date" +
        "|payment-?card-?expiration" +
        "|(^payment-?cc-?date$)" +
        // Rules are from Chromium source codes
        "|expir|exp.*date|^expfield$" +
        "|ablaufdatum|gueltig|gültig" + // de-DE
        "|fecha" + // es
        "|date.*exp" + // fr-FR
        "|scadenza" + // it-IT
        "|有効期限" + // ja-JP
        "|validade" + // pt-BR, pt-PT
        "|Срок действия карты", // ru

      "cc-exp-month":
        // Firefox-specific rules
        "(cc|kk)month" + // de-DE
        // Rules from Bitwarden
        "|(^exp-?month$)" +
        "|(^cc-?exp-?month$)" +
        "|(^cc-?month$)" +
        "|(^card-?month$)" +
        "|(^cc-?mo$)" +
        "|(^card-?mo$)" +
        "|(^exp-?mo$)" +
        "|(^card-?exp-?mo$)" +
        "|(^cc-?exp-?mo$)" +
        "|(^card-?expiration-?month$)" +
        "|(^expiration-?month$)" +
        "|(^cc-?mm$)" +
        "|(^cc-?m$)" +
        "|(^card-?mm$)" +
        "|(^card-?m$)" +
        "|(^card-?exp-?mm$)" +
        "|(^cc-?exp-?mm$)" +
        "|(^exp-?mm$)" +
        "|(^exp-?m$)" +
        "|(^expire-?month$)" +
        "|(^expire-?mo$)" +
        "|(^expiry-?month$)" +
        "|(^expiry-?mo$)" +
        "|(^card-?expire-?month$)" +
        "|(^card-?expire-?mo$)" +
        "|(^card-?expiry-?month$)" +
        "|(^card-?expiry-?mo$)" +
        "|(^mois-?validite$)" +
        "|(^mois-?expiration$)" +
        "|(^m-?validite$)" +
        "|(^m-?expiration$)" +
        "|(^expiry-?date-?field-?month$)" +
        "|(^expiration-?date-?month$)" +
        "|(^expiration-?date-?mm$)" +
        "|(^exp-?mon$)" +
        "|(^validity-?mo$)" +
        "|(^exp-?date-?mo$)" +
        "|(^cb-?date-?mois$)" +
        "|(^date-?m$)" +
        // Rules are from Chromium source codes
        "|exp.*mo|ccmonth|cardmonth|addmonth" +
        "|monat" + // de-DE
        // "|fecha" + // es
        // "|date.*exp" + // fr-FR
        // "|scadenza" + // it-IT
        // "|有効期限" + // ja-JP
        // "|validade" + // pt-BR, pt-PT
        // "|Срок действия карты" + // ru
        "|月", // zh-CN

      "cc-exp-year":
        // Firefox-specific rules
        "(cc|kk)year" + // de-DE
        // Rules from Bitwarden
        "|(^exp-?year$)" +
        "|(^cc-?exp-?year$)" +
        "|(^cc-?year$)" +
        "|(^card-?year$)" +
        "|(^cc-?yr$)" +
        "|(^card-?yr$)" +
        "|(^exp-?yr$)" +
        "|(^card-?exp-?yr$)" +
        "|(^cc-?exp-?yr$)" +
        "|(^card-?expiration-?year$)" +
        "|(^expiration-?year$)" +
        "|(^cc-?yy$)" +
        "|(^cc-?y$)" +
        "|(^card-?yy$)" +
        "|(^card-?y$)" +
        "|(^card-?exp-?yy$)" +
        "|(^cc-?exp-?yy$)" +
        "|(^exp-?yy$)" +
        "|(^exp-?y$)" +
        "|(^cc-?yyyy$)" +
        "|(^card-?yyyy$)" +
        "|(^card-?exp-?yyyy$)" +
        "|(^cc-?exp-?yyyy$)" +
        "|(^expire-?year$)" +
        "|(^expire-?yr$)" +
        "|(^expiry-?year$)" +
        "|(^expiry-?yr$)" +
        "|(^card-?expire-?year$)" +
        "|(^card-?expire-?yr$)" +
        "|(^card-?expiry-?year$)" +
        "|(^card-?expiry-?yr$)" +
        "|(^an-?validite$)" +
        "|(^an-?expiration$)" +
        "|(^annee-?validite$)" +
        "|(^annee-?expiration$)" +
        "|(^expiry-?date-?field-?year$)" +
        "|(^expiration-?date-?year$)" +
        "|(^cb-?date-?ann$)" +
        "|(^expiration-?date-?yy$)" +
        "|(^expiration-?date-?yyyy$)" +
        "|(^validity-?year$)" +
        "|(^exp-?date-?year$)" +
        "|(^date-?y$)" +
        // Rules are from Chromium source codes
        "|(add)?year" +
        "|jahr" + // de-DE
        // "|fecha" + // es
        // "|scadenza" + // it-IT
        // "|有効期限" + // ja-JP
        // "|validade" + // pt-BR, pt-PT
        // "|Срок действия карты" + // ru
        "|年|有效期", // zh-CN

      "cc-type":
        // Firefox-specific rules
        "type" +
        // de-DE
        "|Kartenmarke" +
        // Rules from Bitwarden
        "|(^cc-?type$)" +
        "|(^card-?type$)" +
        "|(^card-?brand$)" +
        "|(^cc-?brand$)" +
        "|(^cb-?type$)",
        // Rules are from Chromium source codes
    },
  ],

  _getRule(name) {
    let rules = [];
    this.RULE_SETS.forEach(set => {
      if (set[name]) {
        rules.push(`(${set[name]})`.normalize("NFKC"));
      }
    });

    const value = new RegExp(rules.join("|"), "iu");
    Object.defineProperty(this.RULES, name, { get: undefined });
    Object.defineProperty(this.RULES, name, { value });
    return value;
  },

  init() {
    Object.keys(this.RULES).forEach(field =>
      Object.defineProperty(this.RULES, field, {
        get() {
          return FathomHeuristicsRegExp._getRule(field);
        },
      })
    );
  },
};

FathomHeuristicsRegExp.init();

const MMRegExp = /^mm$|\(mm\)/i;
const YYorYYYYRegExp = /^(yy|yyyy)$|\(yy\)|\(yyyy\)/i;
const monthRegExp = /month/i;
const yearRegExp = /year/i;
const MMYYRegExp = /mm\s*(\/|\\)\s*yy/i;
const VisaCheckoutRegExp = /visa(-|\s)checkout/i;
const CREDIT_CARD_NETWORK_REGEXP = new RegExp(
  CreditCard.getSupportedNetworks()
    .concat(Object.keys(NETWORK_NAMES))
    .join("|"),
  "gui"
  );
const TwoDigitYearRegExp = /(?:exp.*date[^y\\n\\r]*|mm\\s*[-/]?\\s*)yy(?:[^y]|$)/i;
const FourDigitYearRegExp = /(?:exp.*date[^y\\n\\r]*|mm\\s*[-/]?\\s*)yyyy(?:[^y]|$)/i;
const dwfrmRegExp = /^dwfrm/i;
const bmlRegExp = /bml/i;
const templatedValue = /^\{\{.*\}\}$/;
const firstRegExp = /first/i;
const lastRegExp = /last/i;
const giftRegExp = /gift/i;
const subscriptionRegExp = /subscription/i;

function autocompleteStringMatches(element, ccString) {
  const info = getAutocompleteInfo(element);
  return info.fieldName === ccString;
}

function getFillableFormElements(element) {
  const formLike = FormLikeFactory.createFromField(element);
  return Array.from(formLike.elements).filter(el =>
    FormAutofillUtils.isCreditCardOrAddressFieldType(el)
  );
}

function nextFillableFormField(element) {
  const fillableFormElements = getFillableFormElements(element);
  const elementIndex = fillableFormElements.indexOf(element);
  return fillableFormElements[elementIndex + 1];
}

function previousFillableFormField(element) {
  const fillableFormElements = getFillableFormElements(element);
  const elementIndex = fillableFormElements.indexOf(element);
  return fillableFormElements[elementIndex - 1];
}

function nextFieldPredicateIsTrue(element, predicate) {
  const nextField = nextFillableFormField(element);
  return !!nextField && predicate(nextField);
}

function previousFieldPredicateIsTrue(element, predicate) {
  const previousField = previousFillableFormField(element);
  return !!previousField && predicate(previousField);
}

function nextFieldMatchesExpYearAutocomplete(fnode) {
  return nextFieldPredicateIsTrue(fnode.element, nextField =>
    autocompleteStringMatches(nextField, "cc-exp-year")
  );
}

function previousFieldMatchesExpMonthAutocomplete(fnode) {
  return previousFieldPredicateIsTrue(fnode.element, previousField =>
    autocompleteStringMatches(previousField, "cc-exp-month")
  );
}

//////////////////////////////////////////////
// Attribute Regular Expression Rules
function idOrNameMatchRegExp(element, regExp) {
  for (const str of [element.id, element.name]) {
    if (regExp.test(str)) {
      return true;
    }
  }
  return false;
}

function getElementLabels(element) {
  return {
    *[Symbol.iterator]() {
      const labels = LabelUtils.findLabelElements(element);
      for (let label of labels) {
        yield* LabelUtils.extractLabelStrings(label);
      }
    },
  };
}

function labelsMatchRegExp(element, regExp) {
  const elemStrings = getElementLabels(element);
  for (const str of elemStrings) {
    if (regExp.test(str)) {
      return true;
    }
  }

  const parentElement = element.parentElement;
  // Bug 1634819: element.parentElement is null if element.parentNode is a ShadowRoot
  if (!parentElement) {
    return false;
  }
  // Check if the input is in a <td>, and, if so, check the textContent of the containing <tr>
  if (parentElement.tagName === "TD" && parentElement.parentElement) {
    // TODO: How bad is the assumption that the <tr> won't be the parent of the <td>?
    return regExp.test(parentElement.parentElement.textContent);
  }

  // Check if the input is in a <dd>, and, if so, check the textContent of the preceding <dt>
  if (
    parentElement.tagName === "DD" &&
    // previousElementSibling can be null
    parentElement.previousElementSibling
  ) {
    return regExp.test(parentElement.previousElementSibling.textContent);
  }
  return false;
}

function closestLabelMatchesRegExp(element, regExp) {
  const previousElementSibling = element.previousElementSibling;
  if (
    previousElementSibling !== null &&
    previousElementSibling.tagName === "LABEL"
  ) {
    return regExp.test(previousElementSibling.textContent);
  }

  const nextElementSibling = element.nextElementSibling;
  if (nextElementSibling !== null && nextElementSibling.tagName === "LABEL") {
    return regExp.test(nextElementSibling.textContent);
  }

  return false;
}

function ariaLabelMatchesRegExp(element, regExp) {
  const ariaLabel = element.getAttribute("aria-label");
  return !!ariaLabel && regExp.test(ariaLabel);
}

function placeholderMatchesRegExp(element, regExp) {
  const placeholder = element.getAttribute("placeholder");
  return !!placeholder && regExp.test(placeholder);
}

function nextFieldIdOrNameMatchRegExp(element, regExp) {
  return nextFieldPredicateIsTrue(element, nextField =>
    idOrNameMatchRegExp(nextField, regExp)
  );
}

function nextFieldLabelsMatchRegExp(element, regExp) {
  return nextFieldPredicateIsTrue(element, nextField =>
    labelsMatchRegExp(nextField, regExp)
  );
}

function nextFieldPlaceholderMatchesRegExp(element, regExp) {
  return nextFieldPredicateIsTrue(element, nextField =>
    placeholderMatchesRegExp(nextField, regExp)
  );
}

function nextFieldAriaLabelMatchesRegExp(element, regExp) {
  return nextFieldPredicateIsTrue(element, nextField =>
    ariaLabelMatchesRegExp(nextField, regExp)
  );
}

function previousFieldIdOrNameMatchRegExp(element, regExp) {
  return previousFieldPredicateIsTrue(element, previousField =>
    idOrNameMatchRegExp(previousField, regExp)
  );
}

function previousFieldLabelsMatchRegExp(element, regExp) {
  return previousFieldPredicateIsTrue(element, previousField =>
    labelsMatchRegExp(previousField, regExp)
  );
}

function previousFieldPlaceholderMatchesRegExp(element, regExp) {
  return previousFieldPredicateIsTrue(element, previousField =>
    placeholderMatchesRegExp(previousField, regExp)
  );
}

function previousFieldAriaLabelMatchesRegExp(element, regExp) {
  return previousFieldPredicateIsTrue(element, previousField =>
    ariaLabelMatchesRegExp(previousField, regExp)
  );
}
//////////////////////////////////////////////

function isSelectWithCreditCardOptions(fnode) {
  // Check every select for options that match credit card network names in
  // value or label.
  const element = fnode.element;
  if (element.tagName === "SELECT") {
    for (let option of element.querySelectorAll("option")) {
      if (
        CreditCard.getNetworkFromName(option.value) ||
        CreditCard.getNetworkFromName(option.text)
      ) {
        return true;
      }
    }
  }
  return false;
}

/**
 * If any of the regular expressions match multiple times, we assume the tested
 * string belongs to a radio button for payment type instead of card type.
 *
 * @param {Fnode} fnode
 * @returns {boolean}
 */
function isRadioWithCreditCardText(fnode) {
  const element = fnode.element;
  const inputType = element.type;
  if (!!inputType && inputType === "radio") {
    const valueMatches = element.value.match(CREDIT_CARD_NETWORK_REGEXP);
    if (valueMatches) {
      return valueMatches.length === 1;
    }

    // Here we are checking that only one label matches only one entry in the regular expression.
    const labels = getElementLabels(element);
    let labelsMatched = 0;
    for (const label of labels) {
      const labelMatches = label.match(CREDIT_CARD_NETWORK_REGEXP);
      if (labelMatches) {
        if (labelMatches.length > 1) {
          return false;
        }
        labelsMatched++;
      }
    }
    if (labelsMatched > 0) {
      return labelsMatched === 1;
    }

    const textContentMatches = element.textContent.match(
      CREDIT_CARD_NETWORK_REGEXP
    );
    if (textContentMatches) {
      return textContentMatches.length === 1;
    }
  }
  return false;
}

function matchContiguousSubArray(array, subArray) {
  return array.some((elm, i) =>
    subArray.every((sElem, j) => sElem === array[i + j])
  );
}

function isExpirationMonthLikely(element) {
  if (element.tagName !== "SELECT") {
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
    matchContiguousSubArray(
      options.map(e => +e.value),
      desiredValues
    ) ||
    matchContiguousSubArray(
      options.map(e => +e.label),
      desiredValues
    )
  );
}

function isExpirationYearLikely(element) {
  if (element.tagName !== "SELECT") {
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
    matchContiguousSubArray(
      options.map(e => +e.value),
      desiredValues
    ) ||
    matchContiguousSubArray(
      options.map(e => +e.label),
      desiredValues
    )
  );
}

function nextFieldIsExpirationYearLikely(fnode) {
  return nextFieldPredicateIsTrue(fnode.element, isExpirationYearLikely);
}

function previousFieldIsExpirationMonthLikely(fnode) {
  return previousFieldPredicateIsTrue(fnode.element, isExpirationMonthLikely);
}

function attrsMatchExpWith2Or4DigitYear(fnode, regExpMatchingFunction) {
  const element = fnode.element;
  return (
    regExpMatchingFunction(element, TwoDigitYearRegExp) ||
    regExpMatchingFunction(element, FourDigitYearRegExp)
  );
}

function maxLengthIs(fnode, maxLengthValue) {
  return fnode.element.maxLength === maxLengthValue;
}

function roleIsMenu(fnode) {
  const role = fnode.element.getAttribute("role");
  return !!role && role === "menu";
}

function idOrNameMatchDwfrmAndBml(fnode) {
  return (
    idOrNameMatchRegExp(fnode.element, dwfrmRegExp) &&
    idOrNameMatchRegExp(fnode.element, bmlRegExp)
  );
}

function hasTemplatedValue(fnode) {
  const value = fnode.element.getAttribute("value");
  return !!value && templatedValue.test(value);
}

function inputTypeNotNumbery(fnode) {
  const inputType = fnode.element.type;
  if (inputType) {
    return !["text", "tel", "number"].includes(inputType);
  }
  return false;
}

function idOrNameMatchFirstAndLast(fnode) {
  return (
    idOrNameMatchRegExp(fnode.element, firstRegExp) &&
    idOrNameMatchRegExp(fnode.element, lastRegExp)
  );
}

/**
 * Compactly generate a series of rules that all take a single LHS type with no
 * .when() clause and have only a score() call on the right- hand side.
 *
 * @param {Lhs} inType The incoming fnode type that all rules take
 * @param {object} ruleMap A simple object used as a map with rule names
 *   pointing to scoring callbacks
 * @yields {Rule}
 */
function* simpleScoringRules(inType, ruleMap) {
  for (const [name, scoringCallback] of Object.entries(ruleMap)) {
    yield rule(type(inType), score(scoringCallback), { name });
  }
}

function makeRuleset(coeffs, biases) {
  return ruleset(
    [
      /**
       * Factor out the page scan just for a little more speed during training.
       * This selector is good for most fields. cardType is an exception: it
       * cannot be type=month.
       */
      rule(
        queriedOrClickedElements(
          "input:not([type]), input[type=text], input[type=textbox], input[type=email], input[type=tel], input[type=number], input[type=month], select, button"
        ),
        type("typicalCandidates")
      ),

      /**
       * number rules
       */
      rule(type("typicalCandidates"), type("cc-number")),
      ...simpleScoringRules("cc-number", {
        idOrNameMatchNumberRegExp: fnode =>
          idOrNameMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-number"]
          ),
        labelsMatchNumberRegExp: fnode =>
          labelsMatchRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-number"]),
        closestLabelMatchesNumberRegExp: fnode =>
          closestLabelMatchesRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-number"]),
        placeholderMatchesNumberRegExp: fnode =>
          placeholderMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-number"]
          ),
        ariaLabelMatchesNumberRegExp: fnode =>
          ariaLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-number"]
          ),
        idOrNameMatchGift: fnode =>
          idOrNameMatchRegExp(fnode.element, giftRegExp),
        labelsMatchGift: fnode => labelsMatchRegExp(fnode.element, giftRegExp),
        placeholderMatchesGift: fnode =>
          placeholderMatchesRegExp(fnode.element, giftRegExp),
        ariaLabelMatchesGift: fnode =>
          ariaLabelMatchesRegExp(fnode.element, giftRegExp),
        idOrNameMatchSubscription: fnode =>
          idOrNameMatchRegExp(fnode.element, subscriptionRegExp),
        idOrNameMatchDwfrmAndBml,
        hasTemplatedValue,
        inputTypeNotNumbery,
      }),
      rule(type("cc-number"), out("cc-number")),

      /**
       * name rules
       */
      rule(type("typicalCandidates"), type("cc-name")),
      ...simpleScoringRules("cc-name", {
        idOrNameMatchNameRegExp: fnode =>
          idOrNameMatchRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-name"]),
        labelsMatchNameRegExp: fnode =>
          labelsMatchRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-name"]),
        closestLabelMatchesNameRegExp: fnode =>
          closestLabelMatchesRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-name"]),
        placeholderMatchesNameRegExp: fnode =>
          placeholderMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-name"]
          ),
        ariaLabelMatchesNameRegExp: fnode =>
          ariaLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-name"]
          ),
        idOrNameMatchFirst: fnode =>
          idOrNameMatchRegExp(fnode.element, firstRegExp),
        labelsMatchFirst: fnode =>
          labelsMatchRegExp(fnode.element, firstRegExp),
        placeholderMatchesFirst: fnode =>
          placeholderMatchesRegExp(fnode.element, firstRegExp),
        ariaLabelMatchesFirst: fnode =>
          ariaLabelMatchesRegExp(fnode.element, firstRegExp),
        idOrNameMatchLast: fnode =>
          idOrNameMatchRegExp(fnode.element, lastRegExp),
        labelsMatchLast: fnode => labelsMatchRegExp(fnode.element, lastRegExp),
        placeholderMatchesLast: fnode =>
          placeholderMatchesRegExp(fnode.element, lastRegExp),
        ariaLabelMatchesLast: fnode =>
          ariaLabelMatchesRegExp(fnode.element, lastRegExp),
        idOrNameMatchSubscription: fnode =>
          idOrNameMatchRegExp(fnode.element, subscriptionRegExp),
        idOrNameMatchFirstAndLast,
        idOrNameMatchDwfrmAndBml,
        hasTemplatedValue,
      }),
      rule(type("cc-name"), out("cc-name")),

      /**
       * cardType rules
       */
      rule(
        queriedOrClickedElements(
          "input:not([type]), input[type=text], input[type=textbox], input[type=email], input[type=tel], input[type=number], input[type=radio], select, button"
        ),
        type("cc-type")
      ),
      ...simpleScoringRules("cc-type", {
        idOrNameMatchTypeRegExp: fnode =>
          idOrNameMatchRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-type"]),
        labelsMatchTypeRegExp: fnode =>
          labelsMatchRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-type"]),
        closestLabelMatchesTypeRegExp: fnode =>
          closestLabelMatchesRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-type"]),
        idOrNameMatchVisaCheckout: fnode =>
          idOrNameMatchRegExp(fnode.element, VisaCheckoutRegExp),
        ariaLabelMatchesVisaCheckout: fnode =>
          ariaLabelMatchesRegExp(fnode.element, VisaCheckoutRegExp),
        isSelectWithCreditCardOptions,
        isRadioWithCreditCardText,
        idOrNameMatchSubscription: fnode =>
          idOrNameMatchRegExp(fnode.element, subscriptionRegExp),
        idOrNameMatchDwfrmAndBml,
        hasTemplatedValue,
      }),
      rule(type("cc-type"), out("cc-type")),

      /**
       * expiration rules
       */
      rule(type("typicalCandidates"), type("cc-exp")),
      ...simpleScoringRules("cc-exp", {
        labelsMatchExpRegExp: fnode =>
          labelsMatchRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-exp"]),
        closestLabelMatchesExpRegExp: fnode =>
          closestLabelMatchesRegExp(fnode.element, FathomHeuristicsRegExp.RULES["cc-exp"]),
        placeholderMatchesExpRegExp: fnode =>
          placeholderMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp"]
          ),
        labelsMatchExpWith2Or4DigitYear: fnode =>
          attrsMatchExpWith2Or4DigitYear(fnode, labelsMatchRegExp),
        placeholderMatchesExpWith2Or4DigitYear: fnode =>
          attrsMatchExpWith2Or4DigitYear(fnode, placeholderMatchesRegExp),
        labelsMatchMMYY: fnode => labelsMatchRegExp(fnode.element, MMYYRegExp),
        placeholderMatchesMMYY: fnode =>
          placeholderMatchesRegExp(fnode.element, MMYYRegExp),
        maxLengthIs7: fnode => maxLengthIs(fnode, 7),
        idOrNameMatchSubscription: fnode =>
          idOrNameMatchRegExp(fnode.element, subscriptionRegExp),
        idOrNameMatchDwfrmAndBml,
        hasTemplatedValue,
        isExpirationMonthLikely: fnode =>
          isExpirationMonthLikely(fnode.element),
        isExpirationYearLikely: fnode => isExpirationYearLikely(fnode.element),
        idOrNameMatchMonth: fnode =>
          idOrNameMatchRegExp(fnode.element, monthRegExp),
        idOrNameMatchYear: fnode =>
          idOrNameMatchRegExp(fnode.element, yearRegExp),
        idOrNameMatchExpMonthRegExp: fnode =>
          idOrNameMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        idOrNameMatchExpYearRegExp: fnode =>
          idOrNameMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        idOrNameMatchValidation: fnode =>
          idOrNameMatchRegExp(fnode.element, /validate|validation/i),
      }),
      rule(type("cc-exp"), out("cc-exp")),

      /**
       * expirationMonth rules
       */
      rule(type("typicalCandidates"), type("cc-exp-month")),
      ...simpleScoringRules("cc-exp-month", {
        idOrNameMatchExpMonthRegExp: fnode =>
          idOrNameMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        labelsMatchExpMonthRegExp: fnode =>
          labelsMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        closestLabelMatchesExpMonthRegExp: fnode =>
          closestLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        placeholderMatchesExpMonthRegExp: fnode =>
          placeholderMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        ariaLabelMatchesExpMonthRegExp: fnode =>
          ariaLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        idOrNameMatchMonth: fnode =>
          idOrNameMatchRegExp(fnode.element, monthRegExp),
        labelsMatchMonth: fnode =>
          labelsMatchRegExp(fnode.element, monthRegExp),
        placeholderMatchesMonth: fnode =>
          placeholderMatchesRegExp(fnode.element, monthRegExp),
        ariaLabelMatchesMonth: fnode =>
          ariaLabelMatchesRegExp(fnode.element, monthRegExp),
        nextFieldIdOrNameMatchExpYearRegExp: fnode =>
          nextFieldIdOrNameMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        nextFieldLabelsMatchExpYearRegExp: fnode =>
          nextFieldLabelsMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        nextFieldPlaceholderMatchExpYearRegExp: fnode =>
          nextFieldPlaceholderMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        nextFieldAriaLabelMatchExpYearRegExp: fnode =>
          nextFieldAriaLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        nextFieldIdOrNameMatchYear: fnode =>
          nextFieldIdOrNameMatchRegExp(fnode.element, yearRegExp),
        nextFieldLabelsMatchYear: fnode =>
          nextFieldLabelsMatchRegExp(fnode.element, yearRegExp),
        nextFieldPlaceholderMatchesYear: fnode =>
          nextFieldPlaceholderMatchesRegExp(fnode.element, yearRegExp),
        nextFieldAriaLabelMatchesYear: fnode =>
          nextFieldAriaLabelMatchesRegExp(fnode.element, yearRegExp),
        nextFieldMatchesExpYearAutocomplete,
        isExpirationMonthLikely: fnode =>
          isExpirationMonthLikely(fnode.element),
        nextFieldIsExpirationYearLikely,
        maxLengthIs2: fnode => maxLengthIs(fnode, 2),
        placeholderMatchesMM: fnode =>
          placeholderMatchesRegExp(fnode.element, MMRegExp),
        roleIsMenu,
        idOrNameMatchSubscription: fnode =>
          idOrNameMatchRegExp(fnode.element, subscriptionRegExp),
        idOrNameMatchDwfrmAndBml,
        hasTemplatedValue,
      }),
      rule(type("cc-exp-month"), out("cc-exp-month")),

      /**
       * expirationYear rules
       */
      rule(type("typicalCandidates"), type("cc-exp-year")),
      ...simpleScoringRules("cc-exp-year", {
        idOrNameMatchExpYearRegExp: fnode =>
          idOrNameMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        labelsMatchExpYearRegExp: fnode =>
          labelsMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        closestLabelMatchesExpYearRegExp: fnode =>
          closestLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        placeholderMatchesExpYearRegExp: fnode =>
          placeholderMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        ariaLabelMatchesExpYearRegExp: fnode =>
          ariaLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-year"]
          ),
        idOrNameMatchYear: fnode =>
          idOrNameMatchRegExp(fnode.element, yearRegExp),
        labelsMatchYear: fnode => labelsMatchRegExp(fnode.element, yearRegExp),
        placeholderMatchesYear: fnode =>
          placeholderMatchesRegExp(fnode.element, yearRegExp),
        ariaLabelMatchesYear: fnode =>
          ariaLabelMatchesRegExp(fnode.element, yearRegExp),
        previousFieldIdOrNameMatchExpMonthRegExp: fnode =>
          previousFieldIdOrNameMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        previousFieldLabelsMatchExpMonthRegExp: fnode =>
          previousFieldLabelsMatchRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        previousFieldPlaceholderMatchExpMonthRegExp: fnode =>
          previousFieldPlaceholderMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        previousFieldAriaLabelMatchExpMonthRegExp: fnode =>
          previousFieldAriaLabelMatchesRegExp(
            fnode.element,
            FathomHeuristicsRegExp.RULES["cc-exp-month"]
          ),
        previousFieldIdOrNameMatchMonth: fnode =>
          previousFieldIdOrNameMatchRegExp(fnode.element, monthRegExp),
        previousFieldLabelsMatchMonth: fnode =>
          previousFieldLabelsMatchRegExp(fnode.element, monthRegExp),
        previousFieldPlaceholderMatchesMonth: fnode =>
          previousFieldPlaceholderMatchesRegExp(fnode.element, monthRegExp),
        previousFieldAriaLabelMatchesMonth: fnode =>
          previousFieldAriaLabelMatchesRegExp(fnode.element, monthRegExp),
        previousFieldMatchesExpMonthAutocomplete,
        isExpirationYearLikely: fnode => isExpirationYearLikely(fnode.element),
        previousFieldIsExpirationMonthLikely,
        placeholderMatchesYYOrYYYY: fnode =>
          placeholderMatchesRegExp(fnode.element, YYorYYYYRegExp),
        roleIsMenu,
        idOrNameMatchSubscription: fnode =>
          idOrNameMatchRegExp(fnode.element, subscriptionRegExp),
        idOrNameMatchDwfrmAndBml,
        hasTemplatedValue,
      }),
      rule(type("cc-exp-year"), out("cc-exp-year")),
    ],
    coeffs,
    biases
  );
}

const coefficients = {
  "cc-number": [
    ["idOrNameMatchNumberRegExp", 7.679469585418701],
    ["labelsMatchNumberRegExp", 5.122580051422119],
    ["closestLabelMatchesNumberRegExp", 2.1256935596466064],
    ["placeholderMatchesNumberRegExp", 9.471800804138184],
    ["ariaLabelMatchesNumberRegExp", 6.067715644836426],
    ["idOrNameMatchGift", -22.946273803710938],
    ["labelsMatchGift", -7.852959632873535],
    ["placeholderMatchesGift", -2.355496406555176],
    ["ariaLabelMatchesGift", -2.940307855606079],
    ["idOrNameMatchSubscription", 0.11255314946174622],
    ["idOrNameMatchDwfrmAndBml", -0.0006645023822784424],
    ["hasTemplatedValue", -0.11370040476322174],
    ["inputTypeNotNumbery", -3.750155210494995]
  ],
  "cc-name": [
    ["idOrNameMatchNameRegExp", 7.496212959289551],
    ["labelsMatchNameRegExp", 6.081472873687744],
    ["closestLabelMatchesNameRegExp", 2.600574254989624],
    ["placeholderMatchesNameRegExp", 5.750874042510986],
    ["ariaLabelMatchesNameRegExp", 5.162227153778076],
    ["idOrNameMatchFirst", -6.742659091949463],
    ["labelsMatchFirst", -0.5234538912773132],
    ["placeholderMatchesFirst", -3.4615235328674316],
    ["ariaLabelMatchesFirst", -1.3145145177841187],
    ["idOrNameMatchLast", -12.561869621276855],
    ["labelsMatchLast", -0.27417105436325073],
    ["placeholderMatchesLast", -1.434966802597046],
    ["ariaLabelMatchesLast", -2.9319725036621094],
    ["idOrNameMatchFirstAndLast", 24.123435974121094],
    ["idOrNameMatchSubscription", 0.08349418640136719],
    ["idOrNameMatchDwfrmAndBml", 0.01882520318031311],
    ["hasTemplatedValue", 0.182317852973938]
  ],
  "cc-type": [
    ["idOrNameMatchTypeRegExp", 2.0581533908843994],
    ["labelsMatchTypeRegExp", 1.0784518718719482],
    ["closestLabelMatchesTypeRegExp", 0.6995877623558044],
    ["idOrNameMatchVisaCheckout", -3.320356845855713],
    ["ariaLabelMatchesVisaCheckout", -3.4196767807006836],
    ["isSelectWithCreditCardOptions", 10.337477684020996],
    ["isRadioWithCreditCardText", 4.530318737030029],
    ["idOrNameMatchSubscription", -3.7206356525421143],
    ["idOrNameMatchDwfrmAndBml", -0.08782318234443665],
    ["hasTemplatedValue", 0.1772511601448059]
  ],
  "cc-exp": [
    ["labelsMatchExpRegExp", 7.588159561157227],
    ["closestLabelMatchesExpRegExp", 1.41484534740448],
    ["placeholderMatchesExpRegExp", 8.759064674377441],
    ["labelsMatchExpWith2Or4DigitYear", -3.876218795776367],
    ["placeholderMatchesExpWith2Or4DigitYear", 2.8364884853363037],
    ["labelsMatchMMYY", 8.836017608642578],
    ["placeholderMatchesMMYY", -0.5231751799583435],
    ["maxLengthIs7", 1.3565447330474854],
    ["idOrNameMatchSubscription", 0.1779913753271103],
    ["idOrNameMatchDwfrmAndBml", 0.21037884056568146],
    ["hasTemplatedValue", 0.14900512993335724],
    ["isExpirationMonthLikely", -3.223409652709961],
    ["isExpirationYearLikely", -2.536919593811035],
    ["idOrNameMatchMonth", -3.6893014907836914],
    ["idOrNameMatchYear", -3.108184337615967],
    ["idOrNameMatchExpMonthRegExp", -2.264357089996338],
    ["idOrNameMatchExpYearRegExp", -2.7957723140716553],
    ["idOrNameMatchValidation", -2.29402756690979]
  ],
  "cc-exp-month": [
    ["idOrNameMatchExpMonthRegExp", 0.2787344455718994],
    ["labelsMatchExpMonthRegExp", 1.298413634300232],
    ["closestLabelMatchesExpMonthRegExp", -11.206244468688965],
    ["placeholderMatchesExpMonthRegExp", 1.2605619430541992],
    ["ariaLabelMatchesExpMonthRegExp", 1.1330018043518066],
    ["idOrNameMatchMonth", 6.1464314460754395],
    ["labelsMatchMonth", 0.7051732540130615],
    ["placeholderMatchesMonth", 0.7463492751121521],
    ["ariaLabelMatchesMonth", 1.8244760036468506],
    ["nextFieldIdOrNameMatchExpYearRegExp", 0.06347066164016724],
    ["nextFieldLabelsMatchExpYearRegExp", -0.1692247837781906],
    ["nextFieldPlaceholderMatchExpYearRegExp", 1.0434566736221313],
    ["nextFieldAriaLabelMatchExpYearRegExp", 1.751156210899353],
    ["nextFieldIdOrNameMatchYear", -0.532447338104248],
    ["nextFieldLabelsMatchYear", 1.3248541355133057],
    ["nextFieldPlaceholderMatchesYear", 0.604235827922821],
    ["nextFieldAriaLabelMatchesYear", 1.5364223718643188],
    ["nextFieldMatchesExpYearAutocomplete", 6.285938262939453],
    ["isExpirationMonthLikely", 13.117807388305664],
    ["nextFieldIsExpirationYearLikely", 7.182341575622559],
    ["maxLengthIs2", 4.477289199829102],
    ["placeholderMatchesMM", 14.403288841247559],
    ["roleIsMenu", 5.770959854125977],
    ["idOrNameMatchSubscription", -0.043085768818855286],
    ["idOrNameMatchDwfrmAndBml", 0.02823038399219513],
    ["hasTemplatedValue", 0.07234494388103485]
  ],
  "cc-exp-year": [
    ["idOrNameMatchExpYearRegExp", 5.426016807556152],
    ["labelsMatchExpYearRegExp", 1.3240209817886353],
    ["closestLabelMatchesExpYearRegExp", -8.702284812927246],
    ["placeholderMatchesExpYearRegExp", 0.9059725999832153],
    ["ariaLabelMatchesExpYearRegExp", 0.5550334453582764],
    ["idOrNameMatchYear", 5.362994194030762],
    ["labelsMatchYear", 2.7185044288635254],
    ["placeholderMatchesYear", 0.7883157134056091],
    ["ariaLabelMatchesYear", 0.311492383480072],
    ["previousFieldIdOrNameMatchExpMonthRegExp", 1.8155208826065063],
    ["previousFieldLabelsMatchExpMonthRegExp", -0.46133187413215637],
    ["previousFieldPlaceholderMatchExpMonthRegExp", 1.0374903678894043],
    ["previousFieldAriaLabelMatchExpMonthRegExp", -0.5901495814323425],
    ["previousFieldIdOrNameMatchMonth", -5.960310935974121],
    ["previousFieldLabelsMatchMonth", 0.6495584845542908],
    ["previousFieldPlaceholderMatchesMonth", 0.7198042273521423],
    ["previousFieldAriaLabelMatchesMonth", 3.4590985774993896],
    ["previousFieldMatchesExpMonthAutocomplete", 2.986003875732422],
    ["isExpirationYearLikely", 4.021566390991211],
    ["previousFieldIsExpirationMonthLikely", 9.298635482788086],
    ["placeholderMatchesYYOrYYYY", 10.457176208496094],
    ["roleIsMenu", 1.1051956415176392],
    ["idOrNameMatchSubscription", 0.000688597559928894],
    ["idOrNameMatchDwfrmAndBml", 0.15687309205532074],
    ["hasTemplatedValue", -0.19141331315040588]
  ],
};

const biases = [
  ["cc-number", -4.948795795440674],
  ["cc-name", -5.3578081130981445],
  ["cc-type", -5.979659557342529],
  ["cc-exp", -5.849575996398926],
  ["cc-exp-month", -8.844199180603027],
  ["cc-exp-year", -6.499860763549805],
];

/**
 * END OF CODE PASTED FROM TRAINING REPOSITORY
 */

/**
 * MORE CODE UNIQUE TO PRODUCTION--NOT IN THE TRAINING REPOSITORY:
 */
// Currently there is a bug when a ruleset has multple types (ex, cc-name, cc-number)
// and those types also has the same rules (ex. rule `hasTemplatedValue` is used in
// all the tyoes). When the above case exists, the coefficient of the rule will be
// overwritten, which means, we can't have different coefficient for the same rule on
// different types. To workaround this issue, we create a new ruleset for each type.
export var CreditCardRulesets = {
  init() {
    XPCOMUtils.defineLazyPreferenceGetter(
      this,
      "supportedTypes",
      "extensions.formautofill.creditCards.heuristics.fathom.types",
      null,
      null,
      val => val.split(",")
    );

    for (const type of this.types) {
      if (type) {
        this[type] = makeRuleset([...coefficients[type]], biases);
      }
    }
  },

  get types() {
    return this.supportedTypes;
  },
};

CreditCardRulesets.init();

export default CreditCardRulesets;
