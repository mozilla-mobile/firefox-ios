/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Code that we can share across Firefox Desktop, Firefox Android and Firefox iOS.
 */

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
   * This is a simplified rule of hasLabelMatchingRegex in NewPasswordModel.jsm
   */
  static hasLabelMatchingRegex(element, regex) {
    return regex.test(element.labels?.[0]?.textContent);
  }
}

export { Logic };
