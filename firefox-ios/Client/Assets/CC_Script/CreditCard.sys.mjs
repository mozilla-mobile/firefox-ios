/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// The list of known and supported credit card network ids ("types")
// This list mirrors the networks from dom/payments/BasicCardPayment.cpp
// and is defined by https://www.w3.org/Payments/card-network-ids
const SUPPORTED_NETWORKS = Object.freeze([
  "amex",
  "cartebancaire",
  "diners",
  "discover",
  "jcb",
  "mastercard",
  "mir",
  "unionpay",
  "visa",
]);

// This lists stores lower cased variations of popular credit card network
// names for matching against strings.
export const NETWORK_NAMES = {
  "american express": "amex",
  "master card": "mastercard",
  "union pay": "unionpay",
};

// Based on https://en.wikipedia.org/wiki/Payment_card_number
//
// Notice:
//   - CarteBancaire (`4035`, `4360`) is now recognized as Visa.
//   - UnionPay (`63--`) is now recognized as Discover.
// This means that the order matters.
// First we'll try to match more specific card,
// and if that doesn't match we'll test against the more generic range.
const CREDIT_CARD_IIN = [
  { type: "amex", start: 34, end: 34, len: 15 },
  { type: "amex", start: 37, end: 37, len: 15 },
  { type: "cartebancaire", start: 4035, end: 4035, len: 16 },
  { type: "cartebancaire", start: 4360, end: 4360, len: 16 },
  // We diverge from Wikipedia here, because Diners card
  // support length of 14-19.
  { type: "diners", start: 300, end: 305, len: [14, 19] },
  { type: "diners", start: 3095, end: 3095, len: [14, 19] },
  { type: "diners", start: 36, end: 36, len: [14, 19] },
  { type: "diners", start: 38, end: 39, len: [14, 19] },
  { type: "discover", start: 6011, end: 6011, len: [16, 19] },
  { type: "discover", start: 622126, end: 622925, len: [16, 19] },
  { type: "discover", start: 624000, end: 626999, len: [16, 19] },
  { type: "discover", start: 628200, end: 628899, len: [16, 19] },
  { type: "discover", start: 64, end: 65, len: [16, 19] },
  { type: "jcb", start: 3528, end: 3589, len: [16, 19] },
  { type: "mastercard", start: 2221, end: 2720, len: 16 },
  { type: "mastercard", start: 51, end: 55, len: 16 },
  { type: "mir", start: 2200, end: 2204, len: 16 },
  { type: "unionpay", start: 62, end: 62, len: [16, 19] },
  { type: "unionpay", start: 81, end: 81, len: [16, 19] },
  { type: "visa", start: 4, end: 4, len: 16 },
].sort((a, b) => b.start - a.start);

export class CreditCard {
  /**
   * A CreditCard object represents a credit card, with
   * number, name, expiration, network, and CCV.
   * The number is the only required information when creating
   * an object, all other members are optional. The number
   * is validated during construction and will throw if invalid.
   *
   * @param {string} name, optional
   * @param {string} number
   * @param {string} expirationString, optional
   * @param {string|number} expirationMonth, optional
   * @param {string|number} expirationYear, optional
   * @param {string} network, optional
   * @param {string|number} ccv, optional
   * @param {string} encryptedNumber, optional
   * @throws if number is an invalid credit card number
   */
  constructor({
    name,
    number,
    expirationString,
    expirationMonth,
    expirationYear,
    network,
    ccv,
    encryptedNumber,
  }) {
    this._name = name;
    this._unmodifiedNumber = number;
    this._encryptedNumber = encryptedNumber;
    this._ccv = ccv;
    this.number = number;
    let { month, year } = CreditCard.normalizeExpiration({
      expirationString,
      expirationMonth,
      expirationYear,
    });
    this._expirationMonth = month;
    this._expirationYear = year;
    this.network = network;
  }

  set name(value) {
    this._name = value;
  }

  set expirationMonth(value) {
    if (typeof value == "undefined") {
      this._expirationMonth = undefined;
      return;
    }
    this._expirationMonth = CreditCard.normalizeExpirationMonth(value);
  }

  get expirationMonth() {
    return this._expirationMonth;
  }

  set expirationYear(value) {
    if (typeof value == "undefined") {
      this._expirationYear = undefined;
      return;
    }
    this._expirationYear = CreditCard.normalizeExpirationYear(value);
  }

  get expirationYear() {
    return this._expirationYear;
  }

  set expirationString(value) {
    let { month, year } = CreditCard.parseExpirationString(value);
    this.expirationMonth = month;
    this.expirationYear = year;
  }

  set ccv(value) {
    this._ccv = value;
  }

  get number() {
    return this._number;
  }

  /**
   * Sets the number member of a CreditCard object. If the number
   * is not valid according to the Luhn algorithm then the member
   * will get set to the empty string before throwing an exception.
   *
   * @param {string} value
   * @throws if the value is an invalid credit card number
   */
  set number(value) {
    if (value) {
      let normalizedNumber = CreditCard.normalizeCardNumber(value);
      // Based on the information on wiki[1], the shortest valid length should be
      // 12 digits (Maestro).
      // [1] https://en.wikipedia.org/wiki/Payment_card_number
      normalizedNumber = normalizedNumber.match(/^\d{12,}$/)
        ? normalizedNumber
        : "";
      this._number = normalizedNumber;
    } else {
      this._number = "";
    }

    if (value && !this.isValidNumber()) {
      this._number = "";
      throw new Error("Invalid credit card number");
    }
  }

  get network() {
    return this._network;
  }

  set network(value) {
    this._network = value || undefined;
  }

  // Implements the Luhn checksum algorithm as described at
  // http://wikipedia.org/wiki/Luhn_algorithm
  // Number digit lengths vary with network, but should fall within 12-19 range. [2]
  // More details at https://en.wikipedia.org/wiki/Payment_card_number
  isValidNumber() {
    if (!this._number) {
      return false;
    }

    // Remove dashes and whitespace
    const number = CreditCard.normalizeCardNumber(this._number);

    const len = number.length;
    if (len < 12 || len > 19) {
      return false;
    }

    if (!/^\d+$/.test(number)) {
      return false;
    }

    let total = 0;
    for (let i = 0; i < len; i++) {
      let ch = parseInt(number[len - i - 1], 10);
      if (i % 2 == 1) {
        // Double it, add digits together if > 10
        ch *= 2;
        if (ch > 9) {
          ch -= 9;
        }
      }
      total += ch;
    }
    return total % 10 == 0;
  }

  /**
   * Normalizes a credit card number.
   * @param {string} number
   * @return {string | null}
   * @memberof CreditCard
   */
  static normalizeCardNumber(number) {
    if (!number) {
      return null;
    }
    return number.replace(/[\-\s]/g, "");
  }

  /**
   * Attempts to match the number against known network identifiers.
   *
   * @param {string} ccNumber Credit card number with no spaces or special characters in it.
   *
   * @returns {string|null}
   */
  static getType(ccNumber) {
    if (!ccNumber) {
      return null;
    }

    for (let i = 0; i < CREDIT_CARD_IIN.length; i++) {
      const range = CREDIT_CARD_IIN[i];
      if (typeof range.len == "number") {
        if (range.len != ccNumber.length) {
          continue;
        }
      } else if (
        ccNumber.length < range.len[0] ||
        ccNumber.length > range.len[1]
      ) {
        continue;
      }

      const prefixLength = Math.floor(Math.log10(range.start)) + 1;
      const prefix = parseInt(ccNumber.substring(0, prefixLength), 10);
      if (prefix >= range.start && prefix <= range.end) {
        return range.type;
      }
    }
    return null;
  }

  /**
   * Attempts to retrieve a card network identifier based
   * on a name.
   *
   * @param {string|undefined|null} name
   *
   * @returns {string|null}
   */
  static getNetworkFromName(name) {
    if (!name) {
      return null;
    }
    let lcName = name.trim().toLowerCase().normalize("NFKC");
    if (SUPPORTED_NETWORKS.includes(lcName)) {
      return lcName;
    }
    for (let term in NETWORK_NAMES) {
      if (lcName.includes(term)) {
        return NETWORK_NAMES[term];
      }
    }
    return null;
  }

  /**
   * Returns true if the card number is valid and the
   * expiration date has not passed. Otherwise false.
   *
   * @returns {boolean}
   */
  isValid() {
    if (!this.isValidNumber()) {
      return false;
    }

    let currentDate = new Date();
    let currentYear = currentDate.getFullYear();
    if (this._expirationYear > currentYear) {
      return true;
    }

    // getMonth is 0-based, so add 1 because credit cards are 1-based
    let currentMonth = currentDate.getMonth() + 1;
    return (
      this._expirationYear == currentYear &&
      this._expirationMonth >= currentMonth
    );
  }

  get maskedNumber() {
    return CreditCard.getMaskedNumber(this._number);
  }

  get longMaskedNumber() {
    return CreditCard.getLongMaskedNumber(this._number);
  }

  /**
   * Get credit card display label. It should display masked numbers, the
   * cardholder's name, and the expiration date, separated by a commas.
   * In addition, the card type is provided in the accessibility label.
   */
  static getLabelInfo({ number, name, month, year, type }) {
    let formatSelector = ["number"];
    if (name) {
      formatSelector.push("name");
    }
    if (month && year) {
      formatSelector.push("expiration");
    }
    let stringId = `credit-card-label-${formatSelector.join("-")}-2`;
    return {
      id: stringId,
      args: {
        number: CreditCard.getMaskedNumber(number),
        name,
        month: month?.toString(),
        year: year?.toString(),
        type,
      },
    };
  }

  /**
   *
   * Please use getLabelInfo above, as it allows for localization.
   * @deprecated
   */
  static getLabel({ number, name }) {
    let parts = [];

    if (number) {
      parts.push(CreditCard.getMaskedNumber(number));
    }
    if (name) {
      parts.push(name);
    }
    return parts.join(", ");
  }

  static normalizeExpirationMonth(month) {
    month = parseInt(month, 10);
    if (isNaN(month) || month < 1 || month > 12) {
      return undefined;
    }
    return month;
  }

  static normalizeExpirationYear(year) {
    year = parseInt(year, 10);
    if (isNaN(year) || year < 0) {
      return undefined;
    }
    if (year < 100) {
      year += 2000;
    }
    return year;
  }

  static parseExpirationString(expirationString) {
    let rules = [
      {
        regex: /(?:^|\D)(\d{2})(\d{2})(?!\d)/,
      },
      {
        regex: /(?:^|\D)(\d{4})[-/](\d{1,2})(?!\d)/,
        yearIndex: 0,
        monthIndex: 1,
      },
      {
        regex: /(?:^|\D)(\d{1,2})[-/](\d{4})(?!\d)/,
        yearIndex: 1,
        monthIndex: 0,
      },
      {
        regex: /(?:^|\D)(\d{1,2})[-/](\d{1,2})(?!\d)/,
      },
      {
        regex: /(?:^|\D)(\d{2})(\d{2})(?!\d)/,
      },
    ];

    expirationString = expirationString.replaceAll(" ", "");
    for (let rule of rules) {
      let result = rule.regex.exec(expirationString);
      if (!result) {
        continue;
      }

      let year, month;
      const parsedResults = [parseInt(result[1], 10), parseInt(result[2], 10)];
      if (!rule.yearIndex || !rule.monthIndex) {
        month = parsedResults[0];
        if (month > 12) {
          year = parsedResults[0];
          month = parsedResults[1];
        } else {
          year = parsedResults[1];
        }
      } else {
        year = parsedResults[rule.yearIndex];
        month = parsedResults[rule.monthIndex];
      }

      if (month >= 1 && month <= 12 && (year < 100 || year > 2000)) {
        return { month, year };
      }
    }
    return { month: undefined, year: undefined };
  }

  static normalizeExpiration({
    expirationString,
    expirationMonth,
    expirationYear,
  }) {
    // Only prefer the string version if missing one or both parsed formats.
    let parsedExpiration = {};
    if (expirationString && (!expirationMonth || !expirationYear)) {
      parsedExpiration = CreditCard.parseExpirationString(expirationString);
    }
    return {
      month: CreditCard.normalizeExpirationMonth(
        parsedExpiration.month || expirationMonth
      ),
      year: CreditCard.normalizeExpirationYear(
        parsedExpiration.year || expirationYear
      ),
    };
  }

  static formatMaskedNumber(maskedNumber) {
    return "*".repeat(4) + maskedNumber.substr(-4);
  }

  static getMaskedNumber(number) {
    return "*".repeat(4) + " " + number.substr(-4);
  }

  static getLongMaskedNumber(number) {
    return "*".repeat(number.length - 4) + number.substr(-4);
  }

  static getCreditCardLogo(network) {
    const PATH = "chrome://formautofill/content/";
    const THIRD_PARTY_PATH = PATH + "third-party/";
    switch (network) {
      case "amex":
        return THIRD_PARTY_PATH + "cc-logo-amex.png";
      case "cartebancaire":
        return THIRD_PARTY_PATH + "cc-logo-cartebancaire.png";
      case "diners":
        return THIRD_PARTY_PATH + "cc-logo-diners.svg";
      case "discover":
        return THIRD_PARTY_PATH + "cc-logo-discover.png";
      case "jcb":
        return THIRD_PARTY_PATH + "cc-logo-jcb.svg";
      case "mastercard":
        return THIRD_PARTY_PATH + "cc-logo-mastercard.svg";
      case "mir":
        return THIRD_PARTY_PATH + "cc-logo-mir.svg";
      case "unionpay":
        return THIRD_PARTY_PATH + "cc-logo-unionpay.svg";
      case "visa":
        return THIRD_PARTY_PATH + "cc-logo-visa.svg";
      default:
        return PATH + "icon-credit-card-generic.svg";
    }
  }

  /*
   * Validates the number according to the Luhn algorithm. This
   * method does not throw an exception if the number is invalid.
   */
  static isValidNumber(number) {
    try {
      new CreditCard({ number });
    } catch (ex) {
      return false;
    }
    return true;
  }

  static isValidNetwork(network) {
    return SUPPORTED_NETWORKS.includes(network);
  }

  static getSupportedNetworks() {
    return SUPPORTED_NETWORKS;
  }

  /**
   * Localised names for supported networks are available in
   * `browser/preferences/formAutofill.ftl`.
   */
  static getNetworkL10nId(network) {
    return this.isValidNetwork(network)
      ? `autofill-card-network-${network}`
      : null;
  }
}
