/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * This file is a port of a subset of Chromium's implementation from
 * https://cs.chromium.org/chromium/src/components/password_manager/core/browser/generation/password_generator.cc?l=93&rcl=a896a3ac4ea731b5ab3d2ab5bd76a139885d5c4f
 * which is Copyright 2018 The Chromium Authors. All rights reserved.
 */

const DEFAULT_PASSWORD_LENGTH = 15;
const MAX_UINT8 = Math.pow(2, 8) - 1;
const MAX_UINT32 = Math.pow(2, 32) - 1;

// Some characters are removed due to visual similarity:
const LOWER_CASE_ALPHA = "abcdefghijkmnpqrstuvwxyz"; // no 'l' or 'o'
const UPPER_CASE_ALPHA = "ABCDEFGHJKLMNPQRSTUVWXYZ"; // no 'I' or 'O'
const DIGITS = "23456789"; // no '1' or '0'
const SPECIAL_CHARACTERS = "-~!@#$%^&*_+=)}:;\"'>,.?]";

const REQUIRED_CHARACTER_CLASSES = [
  LOWER_CASE_ALPHA,
  UPPER_CASE_ALPHA,
  DIGITS,
  SPECIAL_CHARACTERS,
];

// Consts for different password rules
const REQUIRED = "required";
const MAX_LENGTH = "maxlength";
const MIN_LENGTH = "minlength";
const MAX_CONSECUTIVE = "max-consecutive";
const UPPER = "upper";
const LOWER = "lower";
const DIGIT = "digit";
const SPECIAL = "special";

// Default password rules
const DEFAULT_RULES = new Map();
DEFAULT_RULES.set(MIN_LENGTH, REQUIRED_CHARACTER_CLASSES.length);
DEFAULT_RULES.set(MAX_LENGTH, MAX_UINT8);
DEFAULT_RULES.set(REQUIRED, [UPPER, LOWER, DIGIT, SPECIAL]);

export const PasswordGenerator = {
  /**
   * @param {Object} options
   * @param {number} options.length - length of the generated password if there are no rules that override the length
   * @param {Map} options.rules - map of password rules
   * @returns {string} password that was generated
   * @throws Error if `length` is invalid
   * @copyright 2018 The Chromium Authors. All rights reserved.
   * @see https://cs.chromium.org/chromium/src/components/password_manager/core/browser/generation/password_generator.cc?l=93&rcl=a896a3ac4ea731b5ab3d2ab5bd76a139885d5c4f
   */
  generatePassword({
    length = DEFAULT_PASSWORD_LENGTH,
    rules = DEFAULT_RULES,
    inputMaxLength,
  }) {
    rules = new Map([...DEFAULT_RULES, ...rules]);
    if (rules.get(MIN_LENGTH) > length) {
      length = rules.get(MIN_LENGTH);
    }
    if (rules.get(MAX_LENGTH) < length) {
      length = rules.get(MAX_LENGTH);
    }
    if (inputMaxLength > 0 && inputMaxLength < length) {
      length = inputMaxLength;
    }

    let password = "";
    let requiredClasses = [];
    let allRequiredCharacters = "";

    // Generate one character of each required class and/or required character list from the rules
    this._addRequiredClassesAndCharacters(rules, requiredClasses);

    // Generate one of each required class
    for (const charClassString of requiredClasses) {
      password +=
        charClassString[this._randomUInt8Index(charClassString.length)];
      if (Array.isArray(charClassString)) {
        // Convert array into single string so that commas aren't
        // concatenated with each character in the arbitrary character array.
        allRequiredCharacters += charClassString.join("");
      } else {
        allRequiredCharacters += charClassString;
      }
    }

    // Now fill the rest of the password with random characters.
    while (password.length < length) {
      password +=
        allRequiredCharacters[
          this._randomUInt8Index(allRequiredCharacters.length)
        ];
    }

    // So far the password contains the minimally required characters at the
    // the beginning. Therefore, we create a random permutation.
    password = this._shuffleString(password);

    // Make sure the password passes the "max-consecutive" rule, if the rule exists
    if (rules.has(MAX_CONSECUTIVE)) {
      // Ensures that a password isn't shuffled an infinite number of times.
      const DEFAULT_NUMBER_OF_SHUFFLES = 15;
      let shuffleCount = 0;
      let consecutiveFlag = this._checkConsecutiveCharacters(
        password,
        rules.get(MAX_CONSECUTIVE)
      );
      while (!consecutiveFlag) {
        password = this._shuffleString(password);
        consecutiveFlag = this._checkConsecutiveCharacters(
          password,
          rules.get(MAX_CONSECUTIVE)
        );
        ++shuffleCount;
        if (shuffleCount === DEFAULT_NUMBER_OF_SHUFFLES) {
          consecutiveFlag = true;
        }
      }
    }

    return password;
  },

  /**
   * Adds special characters and/or other required characters to the requiredCharacters array.
   * @param {Map} rules
   * @param {string[]} requiredClasses
   */
  _addRequiredClassesAndCharacters(rules, requiredClasses) {
    for (const charClass of rules.get(REQUIRED)) {
      if (charClass === UPPER) {
        requiredClasses.push(UPPER_CASE_ALPHA);
      } else if (charClass === LOWER) {
        requiredClasses.push(LOWER_CASE_ALPHA);
      } else if (charClass === DIGIT) {
        requiredClasses.push(DIGITS);
      } else if (charClass === SPECIAL) {
        requiredClasses.push(SPECIAL_CHARACTERS);
      } else {
        requiredClasses.push(charClass);
      }
    }
  },

  /**
   * @param range to generate the number in
   * @returns a random number in range [0, range).
   * @copyright 2018 The Chromium Authors. All rights reserved.
   * @see https://cs.chromium.org/chromium/src/base/rand_util.cc?l=58&rcl=648a59893e4ed5303b5c381b03ce0c75e4165617
   */
  _randomUInt8Index(range) {
    if (range > MAX_UINT8) {
      throw new Error("`range` cannot fit into uint8");
    }
    // We must discard random results above this number, as they would
    // make the random generator non-uniform (consider e.g. if
    // MAX_UINT64 was 7 and |range| was 5, then a result of 1 would be twice
    // as likely as a result of 3 or 4).
    // See https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#Modulo_bias
    const MAX_ACCEPTABLE_VALUE = Math.floor(MAX_UINT8 / range) * range - 1;

    const randomValueArr = new Uint8Array(1);
    do {
      crypto.getRandomValues(randomValueArr);
    } while (randomValueArr[0] > MAX_ACCEPTABLE_VALUE);
    return randomValueArr[0] % range;
  },

  /**
   * Shuffle the order of characters in a string.
   * @param {string} str to shuffle
   * @returns {string} shuffled string
   */
  _shuffleString(str) {
    let arr = Array.from(str);
    // Generate all the random numbers that will be needed.
    const randomValues = new Uint32Array(arr.length - 1);
    crypto.getRandomValues(randomValues);

    // Fisher-Yates Shuffle
    // https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor((randomValues[i - 1] / MAX_UINT32) * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr.join("");
  },

  /**
   * Determine the number of consecutive characters in a string.
   * This is primarily used to validate the "max-consecutive" rule
   * of a generated password.
   * @param {string} generatedPassword
   * @param {number} value the number of consecutive characters allowed
   * @return {boolean} `true` if the generatePassword has less than the value argument number of characters, `false` otherwise
   */
  _checkConsecutiveCharacters(generatedPassword, value) {
    let max = 0;
    for (let start = 0, end = 1; end < generatedPassword.length; ) {
      if (generatedPassword[end] === generatedPassword[start]) {
        if (max < end - start + 1) {
          max = end - start + 1;
          if (max > value) {
            return false;
          }
        }
        end++;
      } else {
        start = end++;
      }
    }
    return true;
  },
  _getUpperCaseCharacters() {
    return UPPER_CASE_ALPHA;
  },
  _getLowerCaseCharacters() {
    return LOWER_CASE_ALPHA;
  },
  _getDigits() {
    return DIGITS;
  },
  _getSpecialCharacters() {
    return SPECIAL_CHARACTERS;
  },
};
