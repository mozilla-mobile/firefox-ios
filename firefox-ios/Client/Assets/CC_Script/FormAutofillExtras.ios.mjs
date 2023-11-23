/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

export class FormAutofillExtras {

  isFocusable(element) {
    let style = window.getComputedStyle(element);
    return !(element.type === 'hidden' || element.offsetParent === null || style.visibility === 'hidden' || style.display === 'none' || style.opacity === '0' || element.hasAttribute('hidden'));
  }

  focusNextInputField() {
    let inputFields = [...document.getElementsByTagName('input')];
    inputFields = inputFields.filter(this.isFocusable);
    const activeElement = document.activeElement;
    const currentIndex = inputFields.indexOf(activeElement);
    const inputFieldCount = inputFields.length - 1;

    if (currentIndex < inputFieldCount) {
      const nextField = inputFields[currentIndex + 1];
      nextField.focus();
    }
  }

  focusPreviousInputField() {
    let inputFields = [...document.getElementsByTagName('input')];
    inputFields = inputFields.filter(this.isFocusable);
    const activeElement = document.activeElement;
    const currentIndex = inputFields.indexOf(activeElement);

    if (currentIndex > 0) {
      const previousField = inputFields[currentIndex - 1];
      previousField.focus();
    }
  }
}

export default FormAutofillExtras;
