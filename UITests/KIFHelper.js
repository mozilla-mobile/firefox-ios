/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var KIFHelper = {
    _currentElement: null,

    /**
     * Sets the selected element to the element with the given text content,
     * or null if no such element exists.
     * @return True if an element was selected
     */
    selectElementWithAccessibilityLabel: function (value) {
        return this._selectElementWithAccessibilityLabel(document.body, value);
    },

    _selectElementWithAccessibilityLabel: function (el, value) {
        if (el.textContent == value || el.title == value) {
            this._currentElement = el;
            return true;
        }

        for (var i = 0; i < el.children.length; i++) {
            if (this._selectElementWithAccessibilityLabel(el.children[i], value)) {
                return true;
            }
        }

        this._currentElement = null;
        return false;
    },

    // TODO: Add support for clicking elements, etc.
};