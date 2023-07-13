/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Represents the detailed information about a form field, including
 * the inferred field name, the approach used for inferring, and additional metadata.
 */
export class FieldDetail {
  // Reference to the elemenet
  elementWeakRef = null;

  // id/name. This is only used for debugging
  identifier = "";

  // The inferred field name for this element
  fieldName = null;

  // The approach we use to infer the information for this element
  // The possible values are "autocomplete", "fathom", and "regex-heuristic"
  reason = null;

  /*
   * The "section", "addressType", and "contactType" values are
   * used to identify the exact field when the serializable data is received
   * from the backend.  There cannot be multiple fields which have
   * the same exact combination of these values.
   */

  // Which section the field belongs to. The value comes from autocomplete attribute.
  // See https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#autofill-detail-tokens for more details
  section = "";
  addressType = "";
  contactType = "";

  // When a field is split into N fields, we use part to record which field it is
  // For example, a credit card number field is split into 4 fields, the value of
  // "part" for the first cc-number field is 1, for the last one is 4.
  // If the field is not split, the value is null
  part = null;

  // Confidence value when the field name is inferred by "fathom"
  confidence = null;

  constructor(
    element,
    fieldName = null,
    { autocompleteInfo = {}, confidence = null } = {}
  ) {
    this.elementWeakRef = new WeakRef(element);
    this.identifier = `${element.id}/${element.name}`;
    this.fieldName = fieldName;

    if (autocompleteInfo) {
      this.reason = "autocomplete";
      this.section = autocompleteInfo.section;
      this.addressType = autocompleteInfo.addressType;
      this.contactType = autocompleteInfo.contactType;
    } else if (confidence) {
      this.reason = "fathom";
      this.confidence = confidence;
    } else {
      this.reason = "regex-heuristic";
    }
  }

  get element() {
    return this.elementWeakRef.deref();
  }

  get sectionName() {
    return this.section || this.addressType;
  }
}

/**
 * A scanner for traversing all elements in a form. It also provides a
 * cursor (parsingIndex) to indicate which element is waiting for parsing.
 *
 * The scanner retrives the field detail by calling heuristics handlers
 * `inferFieldInfo` function.
 */
export class FieldScanner {
  #elementsWeakRef = null;
  #inferFieldInfoFn = null;

  #parsingIndex = 0;

  fieldDetails = [];

  /**
   * Create a FieldScanner based on form elements with the existing
   * fieldDetails.
   *
   * @param {Array.DOMElement} elements
   *        The elements from a form for each parser.
   * @param {Funcion} inferFieldInfoFn
   *        The callback function that is used to infer the field info of a given element
   */
  constructor(elements, inferFieldInfoFn) {
    this.#elementsWeakRef = new WeakRef(elements);
    this.#inferFieldInfoFn = inferFieldInfoFn;
  }

  get #elements() {
    return this.#elementsWeakRef.deref();
  }

  /**
   * This cursor means the index of the element which is waiting for parsing.
   *
   * @returns {number}
   *          The index of the element which is waiting for parsing.
   */
  get parsingIndex() {
    return this.#parsingIndex;
  }

  get parsingFinished() {
    return this.parsingIndex >= this.#elements.length;
  }

  /**
   * Move the parsingIndex to the next elements. Any elements behind this index
   * means the parsing tasks are finished.
   *
   * @param {number} index
   *        The latest index of elements waiting for parsing.
   */
  set parsingIndex(index) {
    if (index > this.#elements.length) {
      throw new Error("The parsing index is out of range.");
    }
    this.#parsingIndex = index;
  }

  /**
   * Retrieve the field detail by the index. If the field detail is not ready,
   * the elements will be traversed until matching the index.
   *
   * @param {number} index
   *        The index of the element that you want to retrieve.
   * @returns {object}
   *          The field detail at the specific index.
   */
  getFieldDetailByIndex(index) {
    if (index >= this.#elements.length) {
      return null;
    }

    if (index < this.fieldDetails.length) {
      return this.fieldDetails[index];
    }

    for (let i = this.fieldDetails.length; i < index + 1; i++) {
      this.pushDetail();
    }

    return this.fieldDetails[index];
  }

  /**
   * This function retrieves the first unparsed element and obtains its
   * information by invoking the `inferFieldInfoFn` callback function.
   * The field information is then stored in a FieldDetail object and
   * appended to the `fieldDetails` array.
   *
   * Any element without the related detail will be used for adding the detail
   * to the end of field details.
   */
  pushDetail() {
    const elementIndex = this.fieldDetails.length;
    if (elementIndex >= this.#elements.length) {
      throw new Error("Try to push the non-existing element info.");
    }
    const element = this.#elements[elementIndex];
    const [fieldName, autocompleteInfo, confidence] =
      this.#inferFieldInfoFn(element);
    const fieldDetail = new FieldDetail(element, fieldName, {
      autocompleteInfo,
      confidence,
    });

    this.fieldDetails.push(fieldDetail);
  }

  /**
   * When a field detail should be changed its fieldName after parsing, use
   * this function to update the fieldName which is at a specific index.
   *
   * @param {number} index
   *        The index indicates a field detail to be updated.
   * @param {string} fieldName
   *        The new name of the field
   * @param {boolean} [ignoreAutocomplete=false]
   *        Whether to change the field name when the field name is determined by
   *        autocomplete attribute
   */
  updateFieldName(index, fieldName, ignoreAutocomplete = false) {
    if (index >= this.fieldDetails.length) {
      throw new Error("Try to update the non-existing field detail.");
    }

    const fieldDetail = this.fieldDetails[index];
    if (fieldDetail.fieldName == fieldName) {
      return;
    }

    if (!ignoreAutocomplete && fieldDetail.reason == "autocomplete") {
      return;
    }

    this.fieldDetails[index].fieldName = fieldName;
    this.fieldDetails[index].reason = "update-heuristic";
  }

  elementExisting(index) {
    return index < this.#elements.length;
  }
}

export default FieldScanner;
