/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Code that we can share across Firefox Desktop, Firefox Android and Firefox iOS.
 */

import { XPCOMUtils } from "resource://gre/modules/XPCOMUtils.sys.mjs";
import { NewPasswordModel } from "resource://gre/modules/shared/NewPasswordModel.sys.mjs";
import { LoginFormFactory } from "resource://gre/modules/shared/LoginFormFactory.sys.mjs";

class Logic {
  static inputTypeIsCompatibleWithUsername(input) {
    const fieldType = input.getAttribute("type")?.toLowerCase() || input.type;
    return (
      ["text", "email", "url", "tel", "number", "search"].includes(fieldType) ||
      fieldType?.includes("user")
    );
  }

  /**
   * Test whether the element has the keyword in its attributes.
   * The tested attributes include id, name, className, and placeholder.
   */
  static elementAttrsMatchRegex(element, regex) {
    if (
      regex.test(element.id) ||
      regex.test(element.name) ||
      regex.test(element.className)
    ) {
      return true;
    }

    const placeholder = element.getAttribute("placeholder");
    return placeholder && regex.test(placeholder);
  }

  /**
   * Test whether associated labels of the element have the keyword.
   * This is a simplified rule of hasLabelMatchingRegex in NewPasswordModel.sys.mjs
   */
  static hasLabelMatchingRegex(element, regex) {
    return regex.test(element.labels?.[0]?.textContent);
  }

  /**
   * Get the parts of the URL we want for identification.
   * Strip out things like the userPass portion and handle javascript:.
   */
  static getLoginOrigin(uriString, allowJS = false) {
    try {
      const mozProxyRegex = /^moz-proxy:\/\//i;
      if (mozProxyRegex.test(uriString)) {
        // Special handling for moz-proxy URIs
        const uri = new URL(uriString.replace(mozProxyRegex, "https://"));
        return `moz-proxy://${uri.host}`;
      }

      const uri = new URL(uriString);
      if (uri.protocol === "javascript:") {
        return allowJS ? "javascript:" : null;
      }

      // Ensure the URL has a host
      // Execption: file URIs See Bug 1651186
      return uri.host || uri.protocol === "file:"
        ? `${uri.protocol}//${uri.host}`
        : null;
    } catch {
      return null;
    }
  }

  static getFormActionOrigin(form) {
    let uriString = form.action;

    // A blank or missing action submits to where it came from.
    if (uriString == "") {
      // ala bug 297761
      uriString = form.baseURI;
    }

    return this.getLoginOrigin(uriString, true);
  }

  /**
   * Checks if a field type is username compatible.
   *
   * @param {Element} element
   *                  the field we want to check.
   * @param {Object} options
   * @param {bool} [options.ignoreConnect] - Whether to ignore checking isConnected
   *                                         of the element.
   *
   * @returns {Boolean} true if the field type is one
   *                    of the username types.
   */
  static isUsernameFieldType(element, { ignoreConnect = false } = {}) {
    if (!HTMLInputElement.isInstance(element)) {
      return false;
    }

    if (!element.isConnected && !ignoreConnect) {
      // If the element isn't connected then it isn't visible to the user so
      // shouldn't be considered. It must have been connected in the past.
      return false;
    }

    if (element.hasBeenTypePassword) {
      return false;
    }

    if (!Logic.inputTypeIsCompatibleWithUsername(element)) {
      return false;
    }

    let acFieldName = element.getAutocompleteInfo().fieldName;
    if (
      !(
        acFieldName == "username" ||
        acFieldName == "webauthn" ||
        // Bug 1540154: Some sites use tel/email on their username fields.
        acFieldName == "email" ||
        acFieldName == "tel" ||
        acFieldName == "tel-national" ||
        acFieldName == "off" ||
        acFieldName == "on" ||
        acFieldName == ""
      )
    ) {
      return false;
    }
    return true;
  }

  /**
   * Checks if a field type is password compatible.
   *
   * @param {Element} element
   *                  the field we want to check.
   * @param {Object} options
   * @param {bool} [options.ignoreConnect] - Whether to ignore checking isConnected
   *                                         of the element.
   *
   * @returns {Boolean} true if the field can
   *                    be treated as a password input
   */
  static isPasswordFieldType(element, { ignoreConnect = false } = {}) {
    if (!HTMLInputElement.isInstance(element)) {
      return false;
    }

    if (!element.isConnected && !ignoreConnect) {
      // If the element isn't connected then it isn't visible to the user so
      // shouldn't be considered. It must have been connected in the past.
      return false;
    }

    if (!element.hasBeenTypePassword) {
      return false;
    }

    // Ensure the element is of a type that could have autocomplete.
    // These include the types with user-editable values. If not, even if it used to be
    // a type=password, we can't treat it as a password input now
    let acInfo = element.getAutocompleteInfo();
    if (!acInfo) {
      return false;
    }

    return true;
  }

  static #cachedNewPasswordScore = new WeakMap();

  static isProbablyANewPasswordField(inputElement) {
    const autocompleteInfo = inputElement.getAutocompleteInfo();
    if (autocompleteInfo.fieldName === "new-password") {
      return true;
    }

    if (Logic.newPasswordFieldFathomThreshold == -1) {
      // Fathom is disabled
      return false;
    }

    let score = this.#cachedNewPasswordScore.get(inputElement);
    if (score) {
      return score >= Logic.newPasswordFieldFathomThreshold;
    }

    const { rules, type } = NewPasswordModel;
    const results = rules.against(inputElement);
    score = results.get(inputElement).scoreFor(type);
    this.#cachedNewPasswordScore.set(inputElement, score);
    return score >= Logic.newPasswordFieldFathomThreshold;
  }

  static findConfirmationField(passwordField) {
    const form = LoginFormFactory.createFromField(passwordField);
    let confirmPasswordInput = null;
    const MAX_CONFIRM_PASSWORD_DISTANCE = 3;

    const startIndex = form.elements.indexOf(passwordField);
    if (startIndex === -1) {
      throw new Error(
        "Password field is not in the form's elements collection"
      );
    }

    // Get a list of input fields to search in.
    // Pre-filter type=hidden fields; they don't count against the distance threshold
    const afterFields = form.elements
      .slice(startIndex + 1)
      .filter(elem => elem.type !== "hidden");

    const acFieldName = passwordField.getAutocompleteInfo()?.fieldName;

    // Match same autocomplete values first
    if (acFieldName === "new-password") {
      const matchIndex = afterFields.findIndex(
        elem =>
          Logic.isPasswordFieldType(elem) &&
          elem.getAutocompleteInfo().fieldName === acFieldName &&
          !elem.disabled &&
          !elem.readOnly
      );
      if (matchIndex >= 0 && matchIndex < MAX_CONFIRM_PASSWORD_DISTANCE) {
        confirmPasswordInput = afterFields[matchIndex];
      }
    }

    if (!confirmPasswordInput) {
      for (
        let idx = 0;
        idx < Math.min(MAX_CONFIRM_PASSWORD_DISTANCE, afterFields.length);
        idx++
      ) {
        if (
          Logic.isPasswordFieldType(afterFields[idx]) &&
          !afterFields[idx].disabled &&
          !afterFields[idx].readOnly
        ) {
          confirmPasswordInput = afterFields[idx];
          break;
        }
      }
    }

    return confirmPasswordInput;
  }
}

XPCOMUtils.defineLazyPreferenceGetter(
  Logic,
  "newPasswordFieldFathomThreshold",
  "signon.generation.confidenceThreshold",
  null,
  null,
  pref => parseFloat(pref)
);

export { Logic };
