/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
  // array consisting of label elements correponding to the id.
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

  generateLabelMap(doc) {
    this._mappedLabels = new Map();
    this._unmappedLabelControls = [];
    this._labelStrings = new WeakMap();

    for (let label of doc.querySelectorAll("label")) {
      let id = label.htmlFor;
      let control;
      if (!id) {
        control = label.control;
        if (!control) {
          // If the label has no control, yet there is a single control
          // adjacent to the label, assume that is meant to be the control.
          let nodes = label.parentNode.querySelectorAll(
            ":scope > :is(input,select)"
          );
          if (nodes.length == 1) {
            control = nodes[0];
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
