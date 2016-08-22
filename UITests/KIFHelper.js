/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var KIFHelper = {
  /**
   * Determines whether an element with the given accessibility label exists.
   * @return True if an element was found
   */
  hasElementWithAccessibilityLabel: function (value) {
    return this._getElementWithAccessibilityLabel(document.body, value) !== null;
  },

  _getElementWithAccessibilityLabel: function (el, value) {
    if (el.textContent == value || el.title == value || el.value == value) {
      return el;
    }

    for (var i = 0; i < el.children.length; i++) {
      var found = this._getElementWithAccessibilityLabel(el.children[i], value);
      if (found) {
        return found;
      }
    }

    return null;
  },

  /**
   * Sets the text for an input element with the given name.
   * @return True if successful
   */
  enterTextIntoInputWithName: function (text, name) {
    var inputs = document.getElementsByName(name);
    if (inputs.length !== 1) {
      return false;
    }

    var input = inputs[0];
    if (input.tagName !== "INPUT") {
      return false;
    }

    input.value = text;
    return true;
  },

  /**
   * Taps an element with the given accessibility label.
   * @return True if successful
   */
  tapElementWithAccessibilityLabel: function (label) {
    var found = this._getElementWithAccessibilityLabel(document.body, label);
    if (found) {
      found.click();
      return true;
    }
    return false;
  },
    
  /**
   * Long presses an element with the given accessibility label, for a given duration.
   * @return True if successful
   */
  longPressElementWithAccessibilityLabel: function (label, duration) {
    var found = this._getElementWithAccessibilityLabel(document.body, label);
    var touches = [new Touch()];
    if (found) {
      var event = new Event("touchstart");
      event.touches = touches;
      found.dispatchEvent(event);
      setTimeout(function () {
        var event = new Event("touchend");
        event.touches = touches;
        found.dispatchEvent(event);
      }, duration);
      return true;
    }
    return false;
  },
};
