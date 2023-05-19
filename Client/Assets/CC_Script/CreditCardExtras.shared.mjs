/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class CreditCardExtras {
  focusNextInputField() {
    var inputFields = document.getElementsByTagName('input');
    var activeElement = document.activeElement;
    var currentIndex = Array.prototype.indexOf.call(inputFields, activeElement);
    var inputFieldCount = inputFields.length - 1;

    if (currentIndex < inputFieldCount) {
      var nextField = inputFields[currentIndex + 1];
      nextField.focus();
    }
  }

  focusPreviousInputField() {
    var inputFields = document.getElementsByTagName('input');
    var activeElement = document.activeElement;
    var currentIndex = Array.prototype.indexOf.call(inputFields, activeElement);

    if (currentIndex > 0) {
      var previousField = inputFields[currentIndex - 1];
      previousField.focus();
    }
  }
}

export { CreditCardExtras };
