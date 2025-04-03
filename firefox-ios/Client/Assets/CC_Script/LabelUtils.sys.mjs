/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  FormAutofillUtils: "resource://gre/modules/shared/FormAutofillUtils.sys.mjs",
});

/**
 * This is a utility object to work with HTML labels in web pages,
 * including finding label elements and label text extraction.
 */
export const LabelUtils = {
  // The tag name list is from Chromium except for "STYLE":
  // eslint-disable-next-line max-len
  // https://cs.chromium.org/chromium/src/components/autofill/content/renderer/form_autofill_util.cc?l=216&rcl=d33a171b7c308a64dc3372fac3da2179c63b419e
  EXCLUDED_TAGS: ["SCRIPT", "NOSCRIPT", "OPTION", "STYLE"],

  // A map object, whose keys are the id's of form fields and each value is an
  // array consisting of label elements correponding to the id. This map only
  // contains those labels with an id that matches a form element.
  // @type {Map<string, array>}
  _mappedLabels: null,

  // An array consisting of label elements whose correponding form field doesn't
  // have an id attribute.
  // @type {Array<[HTMLLabelElement, HTMLElement]>}
  _unmappedLabelControls: null,

  // A weak map consisting of label element and extracted strings pairs.
  // @type {WeakMap<HTMLLabelElement, array>}
  _labelStrings: null,

  /**
   * Extract all strings of an element's children to an array.
   * "element.textContent" is a string which is merged of all children nodes,
   * and this function provides an array of the strings contains in an element.
   *
   * @param  {object} element
   *         A DOM element to be extracted.
   * @returns {Array}
   *          All strings in an element.
   */
  extractLabelStrings(element) {
    if (this._labelStrings.has(element)) {
      return this._labelStrings.get(element);
    }
    let strings = [];
    let _extractLabelStrings = el => {
      if (this.EXCLUDED_TAGS.includes(el.tagName)) {
        return;
      }

      if (el.nodeType == el.TEXT_NODE || !el.childNodes.length) {
        let trimmedText = el.textContent.trim();
        if (trimmedText) {
          strings.push(trimmedText);
        }
        return;
      }

      for (let node of el.childNodes) {
        let nodeType = node.nodeType;
        if (nodeType != node.ELEMENT_NODE && nodeType != node.TEXT_NODE) {
          continue;
        }
        _extractLabelStrings(node);
      }
    };
    _extractLabelStrings(element);
    this._labelStrings.set(element, strings);
    return strings;
  },

  /**
   * From a starting label element, find a nearby input or select element
   * by traversing the nodes in document order, but don't search past another
   * related element or outside the form.
   */
  findAdjacentControl(labelElement, potentialLabels) {
    // First, look for an form element after the label.
    let foundElementAfter = this.findNextFormControl(
      labelElement,
      false,
      potentialLabels
    );

    // If the control has the same parent as the label, return it.
    if (foundElementAfter?.parentNode == labelElement.parentNode) {
      return foundElementAfter;
    }

    // Otherwise, look for a form control with the same parent backwards
    // in the document.
    let foundElementBefore = this.findNextFormControl(
      labelElement,
      true,
      potentialLabels
    );
    if (foundElementBefore?.parentNode == labelElement.parentNode) {
      return foundElementBefore;
    }

    // If there is no form control with the same parent forward or backward,
    // return the form control nearest forward, if any, even though it doesn't
    // have the same parent.
    return foundElementAfter;
  },

  /**
   * Find the next form control in the document tree after a starting label that
   * could correspond to the label. If the form control is in potentialLabels, then
   * it has already been possibly matched to another label so should be ignored.
   *
   *   @param {HTMLLabelElement} element
   *          starting <label> element
   *   @param {boolean} reverse
   *          true to search backwards or false to search forwards
   *   @param {Map} potentialLabels
   *           map of form controls that have already potentially matched
   */
  findNextFormControl(element, reverse, potentialLabels) {
    // Ignore elements and stop searching for elements that are already potentially
    // labelled or are form elements that cannot be autofilled.
    while ((element = this.nextElementInOrder(element, reverse))) {
      if (potentialLabels.has(element)) {
        break;
      } else if (
        lazy.FormAutofillUtils.isCreditCardOrAddressFieldType(element)
      ) {
        return element;
      } else if (
        [
          "button",
          "input",
          "label",
          "meter",
          "output",
          "progress",
          "select",
          "textarea",
        ].includes(element.localName)
      ) {
        break;
      }
    }

    return null;
  },

  nextElementInOrder(element, reverse) {
    let result = reverse ? element.lastElementChild : element.firstElementChild;
    if (result) {
      return result;
    }

    while (element) {
      result = reverse
        ? element.previousElementSibling
        : element.nextElementSibling;
      if (result) {
        return result;
      }

      element = element.parentNode;
      if (
        !element ||
        element.localName == "form" ||
        element.localName == "fieldset"
      ) {
        break;
      }
    }

    return null;
  },

  generateLabelMap(doc) {
    this._mappedLabels = new Map();
    this._unmappedLabelControls = [];
    this._labelStrings = new WeakMap();

    // A map of potential label -> control for labels that don't have an id or
    // control associated with them. Labels that have ids or associated controls
    // will be placed in _mappedLabels.
    let potentialLabels = new Map();

    for (let label of doc.querySelectorAll("label")) {
      let id = label.htmlFor;
      let control;
      if (!id) {
        control = label.control;
        if (!control) {
          // If the label has no control, look for the next input or select
          // element in the document and add that to the potentialLabels list.
          control = this.findAdjacentControl(label, potentialLabels);
          if (control) {
            potentialLabels.set(control, label);
          } else {
            continue;
          }
        }
        id = control.id;
      }
      if (id) {
        let labels = this._mappedLabels.get(id);
        if (labels) {
          labels.push(label);
        } else {
          this._mappedLabels.set(id, [label]);
        }
      } else {
        // control must be non-empty here
        this._unmappedLabelControls.push({ label, control });
      }
    }

    // Now check the potentialLabels list. If any of the labels match form controls
    // that are not bound to a label, add them. This allows a label to match a form
    // control that is nearby even when it has no for attribute or doesn't match an id.
    if (potentialLabels.size) {
      for (let label of potentialLabels) {
        if (
          !this._unmappedLabelControls.some(e => e.control == label[0]) &&
          (!label[1].id || !this._mappedLabels.has(label[1].id))
        ) {
          this._unmappedLabelControls.push({
            label: label[1],
            control: label[0],
          });
        }
      }
    }
  },

  clearLabelMap() {
    this._mappedLabels = null;
    this._unmappedLabelControls = null;
    this._labelStrings = null;
  },

  findLabelElements(element) {
    if (!this._mappedLabels) {
      this.generateLabelMap(element.ownerDocument);
    }

    let id = element.id;
    if (!id) {
      return this._unmappedLabelControls
        .filter(lc => lc.control == element)
        .map(lc => lc.label);
    }
    return this._mappedLabels.get(id) || [];
  },
};

export default LabelUtils;
