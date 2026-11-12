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

  // A map of elements that don't have associated <label> elements but there
  // is nearby text that can form a label. The values in this map are the text.
  _mappedText: null,

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
    let filter = e => {
      // Ignore elements and stop searching for elements that are already
      // potentially labelled or are form elements that cannot be autofilled.
      if (e.nodeType == Node.ELEMENT_NODE) {
        if (potentialLabels.has(e)) {
          return null;
        } else if (lazy.FormAutofillUtils.isCreditCardOrAddressFieldType(e)) {
          // Return this form element.
          return e;
        }
      }

      return false;
    };

    return this.iterateNodes(element, reverse, filter);
  },

  /**
   * Iterate over the nodes in a tree and call the filter on each one. We
   * don't use an existing iterator (such as a TreeWalker) because we want
   * to traverse the tree by visting the parents along the way first. The
   * filter should return exactly false if the node is not accepted and
   * iteration should continue. Otherwise, the value returned by the filter
   * is returned. The iteration also stops and returns null if
   * shouldStopIterating returns true for an element.
   */
  iterateNodes(element, reverse, filter) {
    while (element) {
      let next = reverse ? element.previousSibling : element.nextSibling;
      if (!next) {
        element = element.parentNode;
        if (element && this.shouldStopIterating(element)) {
          return null;
        }
      } else {
        let child = next;
        while (child) {
          if (filter) {
            let filterResult = filter(child);
            if (filterResult !== false) {
              return filterResult;
            }
          }

          if (
            child.nodeType == Node.ELEMENT_NODE &&
            this.shouldStopIterating(child)
          ) {
            return null;
          }

          element = child;
          child = reverse ? child.lastChild : child.firstChild;
        }
      }
    }

    return null;
  },

  // Return true if this is a form control or other element where iterating
  // should stop.
  shouldStopIterating(element) {
    return [
      "button",
      "input",
      "label",
      "meter",
      "output",
      "progress",
      "select",
      "textarea",
      "form",
      "fieldset",
      "script",
      "style",
    ].includes(element.localName);
  },

  /**
   * Given an element that doesn't have an associated label, iterate backwards
   * and find inline text nearby that likely serves as the label.
   */
  findNearbyText(element) {
    if (this._mappedText.has(element)) {
      return this._mappedText.get(element);
    }

    let txt = "";
    let current = element;

    // A simple guard to prevent searching too far.
    let count = 10;

    let returnTextNode = node => {
      // As a shortcut, if text was already found, stop iterating when a
      // div element was found.
      if (
        !count-- ||
        (current.nodeType == Node.ELEMENT_NODE &&
          current.localName == "div" &&
          txt.length)
      ) {
        return null;
      }

      return node.nodeType == Node.TEXT_NODE ? node : false;
    };

    while ((current = this.iterateNodes(current, true, returnTextNode))) {
      let textContent = current.nodeValue;
      if (textContent) {
        // Prepend the found text.
        txt = textContent + txt;
      }
    }

    // Always add the element even where there is no text, so that it isn't
    // searched for again.
    txt = txt.replace(/\s{2,}/g, " ").trim(); // Collapse duplicate whitespaces
    this._mappedText.set(element, txt);
    return txt;
  },

  generateLabelMap(doc) {
    this._mappedLabels = new Map();
    this._mappedText = new Map();
    this._labelStrings = new WeakMap();

    // A map of potential label -> control for labels that don't have an id or
    // control associated with them. Labels that have ids or associated controls
    // will be placed in _mappedLabels.
    let potentialLabels = new Map();
    for (let label of doc.querySelectorAll("label")) {
      let control = label.control;
      if (control) {
        const controlId = lazy.FormAutofillUtils.getElementIdentifier(control);
        let labels = this._mappedLabels.get(controlId);
        if (labels) {
          labels.push(label);
        } else {
          this._mappedLabels.set(controlId, [label]);
        }
      } else {
        // If the label has no control, look for the next input or select
        // element in the document and add that to the potentialLabels list.
        control = this.findAdjacentControl(label, potentialLabels);
        if (control) {
          potentialLabels.set(control, label);
        }
      }
    }

    // Now check the potentialLabels list. If any of the labels match form controls
    // that are not bound to a label, add them. This allows a label to match a form
    // control that is nearby even when it has no for attribute or doesn't match an id.
    if (potentialLabels.size) {
      for (let label of potentialLabels) {
        const elementId = lazy.FormAutofillUtils.getElementIdentifier(label[0]);
        if (!this._mappedLabels.has(elementId)) {
          this._mappedLabels.set(elementId, [label[1]]);
        }
      }
    }
  },

  clearLabelMap() {
    this._mappedLabels = null;
    this._mappedText = null;
    this._labelStrings = null;
  },

  findLabelElements(element) {
    if (!this._mappedLabels) {
      this.generateLabelMap(element.ownerDocument);
    }

    let id = lazy.FormAutofillUtils.getElementIdentifier(element);
    return this._mappedLabels.get(id) || [];
  },
};

export default LabelUtils;
