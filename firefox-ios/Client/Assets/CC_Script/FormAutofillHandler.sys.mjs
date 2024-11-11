/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  AddressParser: "resource://gre/modules/shared/AddressParser.sys.mjs",
  AutofillFormFactory:
    "resource://gre/modules/shared/AutofillFormFactory.sys.mjs",
  CreditCard: "resource://gre/modules/CreditCard.sys.mjs",
  FieldDetail: "resource://gre/modules/shared/FieldScanner.sys.mjs",
  FormAutofillHeuristics:
    "resource://gre/modules/shared/FormAutofillHeuristics.sys.mjs",
  FormAutofillNameUtils:
    "resource://gre/modules/shared/FormAutofillNameUtils.sys.mjs",
  LabelUtils: "resource://gre/modules/shared/LabelUtils.sys.mjs",
});

const { FIELD_STATES } = FormAutofillUtils;

/**
 * Handles profile autofill for a DOM Form element.
 */
export class FormAutofillHandler {
  // The window to which this form belongs
  window = null;

  // DOM Form element to which this object is attached
  form = null;

  // Keeps track of filled state for all identified elements
  #filledStateByElement = new WeakMap();

  // An object that caches the current selected option, keyed by element.
  #matchingSelectOption = null;

  /**
   * Array of collected data about relevant form fields.  Each item is an object
   * storing the identifying details of the field and a reference to the
   * originally associated element from the form.
   *
   * The "section", "addressType", "contactType", and "fieldName" values are
   * used to identify the exact field when the serializable data is received
   * from the backend.  There cannot be multiple fields which have
   * the same exact combination of these values.
   *
   * A direct reference to the associated element cannot be sent to the user
   * interface because processing may be done in the parent process.
   */
  #fieldDetails = null;

  /**
   * Initialize the form from `FormLike` object to handle the section or form
   * operations.
   *
   * @param {FormLike} form Form that need to be auto filled
   * @param {Function} onFilledModifiedCallback Function that can be invoked
   *                   when we want to suggest autofill on a form.
   */
  constructor(form, onFilledModifiedCallback = () => {}) {
    this._updateForm(form);

    this.window = this.form.rootElement.ownerGlobal;

    this.onFilledModifiedCallback = onFilledModifiedCallback;

    // The identifier generated via ContentDOMReference for the root element.
    this.rootElementId = FormAutofillUtils.getElementIdentifier(
      form.rootElement
    );

    ChromeUtils.defineLazyGetter(this, "log", () =>
      FormAutofill.defineLogGetter(this, "FormAutofillHandler")
    );
  }

  /**
   * Retrieves the 'fieldDetails' property, ensuring it has been initialized by
   * `setIdentifiedFieldDetails`. Throws an error if accessed before initialization.
   *
   * This is because 'fieldDetail'' contains information that need to be computed
   * in the parent side first.
   *
   * @throws {Error} If `setIdentifiedFieldDetails` has not been called.
   * @returns {Array<FieldDetail>}
   *          The list of autofillable field details for this form.
   */
  get fieldDetails() {
    if (!this.#fieldDetails) {
      throw new Error(
        `Should only use 'fieldDetails' after 'setIdentifiedFieldDetails' is called`
      );
    }
    return this.#fieldDetails;
  }

  /**
   * Sets the list of 'FieldDetail' objects for autofillable fields within the form.
   *
   * @param {Array<FieldDetail>} fieldDetails
   *        An array of field details that has been computed on the parent side.
   *        This method should be called before accessing `fieldDetails`.
   */
  setIdentifiedFieldDetails(fieldDetails) {
    this.#fieldDetails = fieldDetails;
  }

  /**
   * Determines whether 'setIdentifiedFieldDetails' has been called and the
   * `fieldDetails` have been initialized.
   *
   * @returns {boolean}
   *          True if 'fieldDetails' has been initialized; otherwise, False.
   */
  hasIdentifiedFields() {
    return !!this.#fieldDetails;
  }

  handleEvent(event) {
    switch (event.type) {
      case "input": {
        if (!event.isTrusted) {
          return;
        }

        // This uses the #filledStateByElement map instead of
        // autofillState as the state has already been cleared by the time
        // the input event fires.
        const fieldDetail = this.getFieldDetailByElement(event.target);
        const previousState = this.getFilledStateByElement(event.target);
        const newState = FIELD_STATES.NORMAL;

        if (previousState != newState) {
          this.changeFieldState(fieldDetail, newState);
        }

        this.onFilledModifiedCallback?.(fieldDetail, previousState, newState);
      }
    }
  }

  getFieldDetailByName(fieldName) {
    return this.fieldDetails.find(detail => detail.fieldName == fieldName);
  }

  getFieldDetailByElement(element) {
    return this.fieldDetails.find(detail => detail.element == element);
  }

  getFieldDetailByElementId(elementId) {
    return this.fieldDetails.find(detail => detail.elementId == elementId);
  }

  /**
   * Only use this API within handleEvent
   */
  getFilledStateByElement(element) {
    return this.#filledStateByElement.get(element);
  }

  /**
   * Check the form is necessary to be updated. This function should be able to
   * detect any changes including all control elements in the form.
   *
   * @param {HTMLElement} element The element supposed to be in the form.
   * @returns {boolean} FormAutofillHandler.form is updated or not.
   */
  updateFormIfNeeded(element) {
    // When the following condition happens, FormAutofillHandler.form should be
    // updated:
    // * The count of form controls is changed.
    // * When the element can not be found in the current form.
    //
    // However, we should improve the function to detect the element changes.
    // e.g. a tel field is changed from type="hidden" to type="tel".

    let _formLike;
    const getFormLike = () => {
      if (!_formLike) {
        _formLike = lazy.AutofillFormFactory.createFromField(element);
      }
      return _formLike;
    };

    const currentForm = getFormLike();
    if (currentForm.elements.length != this.form.elements.length) {
      this.log.debug("The count of form elements is changed.");
      this._updateForm(getFormLike());
      return true;
    }

    if (!this.form.elements.includes(element)) {
      this.log.debug("The element can not be found in the current form.");
      this._updateForm(getFormLike());
      return true;
    }

    return false;
  }

  /**
   * Update the form with a new FormLike, and the related fields should be
   * updated or clear to ensure the data consistency.
   *
   * @param {FormLike} form a new FormLike to replace the original one.
   */
  _updateForm(form) {
    this.form = form;

    this.#fieldDetails = null;
  }

  /**
   * Collect <input>, <select>, and <iframe> elements from the specified form
   * and return the correspond 'FieldDetail' objects.
   *
   * @param {HTMLFormElement} form
   *        The form that we collect information from.
   *
   * @returns {Array<FieldDeail>}
   *        An array containing eliglble fields for autofill, also
   *        including iframe.
   */
  static collectFormFields(form) {
    const fieldDetails = lazy.FormAutofillHeuristics.getFormInfo(form) ?? [];

    let index = 0;
    const fieldDetailsIncludeIframe = [];
    const elements = form.rootElement.querySelectorAll("input, select, iframe");

    for (const element of elements) {
      if (fieldDetails[index]?.element == element) {
        fieldDetailsIncludeIframe.push(fieldDetails[index]);
        index++;
      } else if (
        element.localName == "iframe" &&
        FormAutofillUtils.isFieldVisible(element)
      ) {
        const iframeFd = lazy.FieldDetail.create(element, form, "iframe");
        fieldDetailsIncludeIframe.push(iframeFd);
      }
    }
    return fieldDetailsIncludeIframe;
  }

  /**
   * Change the state of a field to correspond with different presentations.
   *
   * @param {object} fieldDetail
   *        A fieldDetail of which its element is about to update the state.
   * @param {string} state
   *        The state to apply.
   */
  changeFieldState(fieldDetail, state) {
    const element = fieldDetail.element;
    if (!element) {
      this.log.warn(
        fieldDetail.fieldName,
        "is unreachable while changing state"
      );
      return;
    }

    if (!Object.values(FIELD_STATES).includes(state)) {
      this.log.warn(
        fieldDetail.fieldName,
        "is trying to change to an invalid state"
      );
      return;
    }

    element.autofillState = state;
    this.#filledStateByElement.set(element, state);

    if (state == FIELD_STATES.AUTO_FILLED) {
      element.addEventListener("input", this, { mozSystemGroup: true });
    }
  }

  /**
   * Populates result to the preview layers with given profile.
   *
   * @param {Array} elementIds
   * @param {object} profile
   *        A profile to be previewed with
   */
  previewFields(elementIds, profile) {
    this.getAdaptedProfiles([profile]);

    for (const fieldDetail of this.fieldDetails) {
      const element = fieldDetail.element;

      // Skip the field if it is null or readonly or disabled
      if (
        !elementIds.includes(fieldDetail.elementId) ||
        !FormAutofillUtils.isFieldAutofillable(element)
      ) {
        continue;
      }

      let value = this.getFilledValueFromProfile(fieldDetail, profile);
      if (!value) {
        this.changeFieldState(fieldDetail, FIELD_STATES.NORMAL);
        continue;
      }

      if (HTMLInputElement.isInstance(element)) {
        if (element.value && element.value != element.defaultValue) {
          // Skip the field if the user has already entered text and that text
          // is not the site prefilled value.
          continue;
        }
      } else if (HTMLSelectElement.isInstance(element)) {
        // Unlike text input, select element is always previewed even if
        // the option is already selected.
        const option = this.matchSelectOptions(fieldDetail, profile);
        value = option?.text ?? "";
      } else {
        continue;
      }

      element.previewValue = value?.toString().replaceAll("*", "•");
      this.changeFieldState(fieldDetail, FIELD_STATES.PREVIEW);
    }
  }

  /**
   * Processes form fields that can be autofilled, and populates them with the
   * profile provided by backend.
   *
   * @param {string} focusedId
   *        The id of the element that triggers autofilling.
   * @param {Array} elementIds
   *        An array of IDs for the elements that should be autofilled.
   * @param {object} profile
   *        The data profile containing the values to be autofilled into the form fields.
   */
  fillFields(focusedId, elementIds, profile) {
    this.getAdaptedProfiles([profile]);

    for (const fieldDetail of this.fieldDetails) {
      const { element, elementId } = fieldDetail;

      if (
        !elementIds.includes(elementId) ||
        !FormAutofillUtils.isFieldAutofillable(element)
      ) {
        continue;
      }

      element.previewValue = "";

      if (HTMLInputElement.isInstance(element)) {
        // Bug 1687679: Since profile appears to be presentation ready data, we need to utilize the "x-formatted" field
        // that is generated when presentation ready data doesn't fit into the autofilling element.
        // For example, autofilling expiration month into an input element will not work as expected if
        // the month is less than 10, since the input is expected a zero-padded string.
        // See Bug 1722941 for follow up.
        const value = this.getFilledValueFromProfile(fieldDetail, profile);
        if (!value) {
          continue;
        }

        // For the focused input element, it will be filled with a valid value
        // anyway.
        // For the others, the fields should be only filled when their values are empty
        // or their values are equal to the site prefill value
        // or are the result of an earlier auto-fill.
        if (
          elementId == focusedId ||
          !element.value ||
          element.value == element.defaultValue ||
          element.autofillState == FIELD_STATES.AUTO_FILLED
        ) {
          FormAutofillHandler.fillFieldValue(element, value);
          this.changeFieldState(fieldDetail, FIELD_STATES.AUTO_FILLED);
        }
      } else if (HTMLSelectElement.isInstance(element)) {
        const option = this.matchSelectOptions(fieldDetail, profile);
        if (!option) {
          continue;
        }

        // Do not change value or dispatch events if the option is already selected.
        // Use case for multiple select is not considered here.
        if (!option.selected) {
          option.selected = true;
          FormAutofillHandler.fillFieldValue(element, option.value);
        }
        // Autofill highlight appears regardless if value is changed or not
        this.changeFieldState(fieldDetail, FIELD_STATES.AUTO_FILLED);
      } else {
        continue;
      }
    }

    FormAutofillUtils.getElementByIdentifier(focusedId)?.focus({
      preventScroll: true,
    });

    this.registerFormChangeHandler();
  }

  registerFormChangeHandler() {
    if (this.onChangeHandler) {
      return;
    }

    this.log.debug("register change handler for filled form:", this.form);

    this.onChangeHandler = e => {
      if (!e.isTrusted) {
        return;
      }
      if (e.type == "reset") {
        for (const fieldDetail of this.fieldDetails) {
          const element = fieldDetail.element;
          element.removeEventListener("input", this, { mozSystemGroup: true });
          this.changeFieldState(fieldDetail, FIELD_STATES.NORMAL);
        }
      }

      // Unregister listeners once no field is in AUTO_FILLED state.
      if (
        this.fieldDetails.every(
          detail => detail.element.autofillState != FIELD_STATES.AUTO_FILLED
        )
      ) {
        this.form.rootElement.removeEventListener(
          "input",
          this.onChangeHandler,
          {
            mozSystemGroup: true,
          }
        );
        this.form.rootElement.removeEventListener(
          "reset",
          this.onChangeHandler,
          {
            mozSystemGroup: true,
          }
        );
        this.onChangeHandler = null;
      }
    };

    // Handle the highlight style resetting caused by user's correction afterward.
    this.log.debug("register change handler for filled form:", this.form);
    this.form.rootElement.addEventListener("input", this.onChangeHandler, {
      mozSystemGroup: true,
    });
    this.form.rootElement.addEventListener("reset", this.onChangeHandler, {
      mozSystemGroup: true,
    });
  }

  computeFillingValue(fieldDetail) {
    const element = fieldDetail.element;
    if (!element) {
      return null;
    }

    let value = element.value.trim();
    switch (fieldDetail.fieldName) {
      case "address-level1":
        if (HTMLSelectElement.isInstance(element)) {
          // Don't save the record when the option value is empty *OR* there
          // are multiple options being selected. The empty option is usually
          // assumed to be default along with a meaningless text to users.
          if (!value || element.selectedOptions.length != 1) {
            // Keep the property and preserve more information for address updating
            value = "";
          } else {
            const text = element.selectedOptions[0].text.trim();
            value =
              FormAutofillUtils.getAbbreviatedSubregionName([value, text]) ||
              text;
          }
        }
        break;
      case "country":
        // This is a temporary fix. Ideally we should have either case-insensitive comparison of country codes
        // or handle this elsewhere see Bug 1889234 for more context.
        value = value.toUpperCase();
        break;
      case "cc-type":
        if (
          HTMLSelectElement.isInstance(element) &&
          !lazy.CreditCard.isValidNetwork(value)
        ) {
          // Don't save the record when the option value is empty *OR* there
          // are multiple options being selected. The empty option is usually
          // assumed to be default along with a meaningless text to users.
          if (value && element.selectedOptions.length == 1) {
            const selectedOption = element.selectedOptions[0];
            const networkType =
              lazy.CreditCard.getNetworkFromName(selectedOption.text) ??
              lazy.CreditCard.getNetworkFromName(selectedOption.value);
            if (networkType) {
              value = networkType;
            }
          }
        }
        break;
    }

    return value;
  }

  /*
   * Apply both address and credit card related transformers.
   *
   * @param {Object} profile
   *        A profile for adjusting credit card related value.
   * @override
   */
  applyTransformers(profile) {
    this.addressTransformer(profile);
    this.telTransformer(profile);
    this.creditCardExpiryDateTransformer(profile);
    this.creditCardExpMonthAndYearTransformer(profile);
    this.creditCardNameTransformer(profile);
    this.adaptFieldMaxLength(profile);
  }

  getAdaptedProfiles(originalProfiles) {
    for (let profile of originalProfiles) {
      this.applyTransformers(profile);
    }
    return originalProfiles;
  }

  /**
   * Match the select option for a field if we autofill with the given profile.
   * This function caches the matching result in the `#matchingSelectionOption`
   * variable.
   *
   * @param {FieldDetail} fieldDetail
   *        The field information of the matching element.
   * @param {object} profile
   *        The profile used for autofill.
   *
   * @returns {Option}
   *        The matched option, or undefined if no matching option is found.
   */
  matchSelectOptions(fieldDetail, profile) {
    if (!this.#matchingSelectOption) {
      this.#matchingSelectOption = new WeakMap();
    }

    const { element, fieldName } = fieldDetail;
    if (!HTMLSelectElement.isInstance(element)) {
      return undefined;
    }

    const cache = this.#matchingSelectOption.get(element) || {};
    const value = profile[fieldName];

    let option = cache[value]?.deref();
    if (!option) {
      option = FormAutofillUtils.findSelectOption(element, profile, fieldName);

      if (option) {
        cache[value] = new WeakRef(option);
        this.#matchingSelectOption.set(element, cache);
      } else if (cache[value]) {
        delete cache[value];
        this.#matchingSelectOption.set(element, cache);
      }
    }

    return option;
  }

  adaptFieldMaxLength(profile) {
    for (let key in profile) {
      let detail = this.getFieldDetailByName(key);
      if (!detail || detail.part) {
        continue;
      }

      let element = detail.element;
      if (!element) {
        continue;
      }

      let maxLength = element.maxLength;
      if (
        maxLength === undefined ||
        maxLength < 0 ||
        profile[key].toString().length <= maxLength
      ) {
        continue;
      }

      if (maxLength) {
        switch (typeof profile[key]) {
          case "string":
            // If this is an expiration field and our previous
            // adaptations haven't resulted in a string that is
            // short enough to satisfy the field length, and the
            // field is constrained to a length of 4 or 5, then we
            // assume it is intended to hold an expiration of the
            // form "MMYY" or "MM/YY".
            if (key == "cc-exp" && (maxLength == 4 || maxLength == 5)) {
              const month2Digits = (
                "0" + profile["cc-exp-month"].toString()
              ).slice(-2);
              const year2Digits = profile["cc-exp-year"].toString().slice(-2);
              const separator = maxLength == 5 ? "/" : "";
              profile[key] = `${month2Digits}${separator}${year2Digits}`;
            } else if (key == "cc-number") {
              // We want to show the last four digits of credit card so that
              // the masked credit card previews correctly and appears correctly
              // in the autocomplete menu
              profile[key] = profile[key].substr(
                profile[key].length - maxLength
              );
            } else {
              profile[key] = profile[key].substr(0, maxLength);
            }
            break;
          case "number":
            // There's no way to truncate a number smaller than a
            // single digit.
            if (maxLength < 1) {
              maxLength = 1;
            }
            // The only numbers we store are expiration month/year,
            // and if they truncate, we want the final digits, not
            // the initial ones.
            profile[key] = profile[key] % Math.pow(10, maxLength);
            break;
          default:
        }
      } else {
        delete profile[key];
        delete profile[`${key}-formatted`];
      }
    }
  }

  /**
   * Handles credit card expiry date transformation when
   * the expiry date exists in a cc-exp field.
   *
   * @param {object} profile
   */
  creditCardExpiryDateTransformer(profile) {
    if (!profile["cc-exp"]) {
      return;
    }

    const element = this.getFieldDetailByName("cc-exp")?.element;
    if (!element) {
      return;
    }

    function updateExpiry(_string, _month, _year) {
      // Bug 1687681: This is a short term fix to other locales having
      // different characters to represent year.
      // - FR locales may use "A" to represent year.
      // - DE locales may use "J" to represent year.
      // - PL locales may use "R" to represent year.
      // This approach will not scale well and should be investigated in a follow up bug.
      const monthChars = "m";
      const yearChars = "yy|aa|jj|rr";
      const expiryDateFormatRegex = (firstChars, secondChars) =>
        new RegExp(
          "(?:\\b|^)((?:[" +
            firstChars +
            "]{2}){1,2})\\s*([\\-/])\\s*((?:[" +
            secondChars +
            "]{2}){1,2})(?:\\b|$)",
          "i"
        );

      // If the month first check finds a result, where placeholder is "mm - yyyy",
      // the result will be structured as such: ["mm - yyyy", "mm", "-", "yyyy"]
      let result = expiryDateFormatRegex(monthChars, yearChars).exec(_string);
      if (result) {
        return (
          _month.padStart(result[1].length, "0") +
          result[2] +
          _year.substr(-1 * result[3].length)
        );
      }

      // If the year first check finds a result, where placeholder is "yyyy mm",
      // the result will be structured as such: ["yyyy mm", "yyyy", " ", "mm"]
      result = expiryDateFormatRegex(yearChars, monthChars).exec(_string);
      if (result) {
        return (
          _year.substr(-1 * result[1].length) +
          result[2] +
          _month.padStart(result[3].length, "0")
        );
      }
      return null;
    }

    let newExpiryString = null;
    const month = profile["cc-exp-month"].toString();
    const year = profile["cc-exp-year"].toString();
    if (element.localName == "input") {
      // Use the placeholder or label to determine the expiry string format.
      const possibleExpiryStrings = [];
      if (element.placeholder) {
        possibleExpiryStrings.push(element.placeholder);
      }
      const labels = lazy.LabelUtils.findLabelElements(element);
      if (labels) {
        // Not consider multiple lable for now.
        possibleExpiryStrings.push(element.labels[0]?.textContent);
      }
      if (element.previousElementSibling?.localName == "label") {
        possibleExpiryStrings.push(element.previousElementSibling.textContent);
      }

      possibleExpiryStrings.some(string => {
        newExpiryString = updateExpiry(string, month, year);
        return !!newExpiryString;
      });
    }

    // Bug 1688576: Change YYYY-MM to MM/YYYY since MM/YYYY is the
    // preferred presentation format for credit card expiry dates.
    profile["cc-exp"] = newExpiryString ?? `${month.padStart(2, "0")}/${year}`;
  }

  /**
   * Handles credit card expiry date transformation when the expiry date exists in
   * the separate cc-exp-month and cc-exp-year fields
   *
   * @param {object} profile
   */
  creditCardExpMonthAndYearTransformer(profile) {
    const getInputElementByField = (field, self) => {
      if (!field) {
        return null;
      }
      const detail = self.getFieldDetailByName(field);
      if (!detail) {
        return null;
      }
      const element = detail.element;
      return element.localName === "input" ? element : null;
    };
    const month = getInputElementByField("cc-exp-month", this);
    if (month) {
      // Transform the expiry month to MM since this is a common format needed for filling.
      profile["cc-exp-month-formatted"] = profile["cc-exp-month"]
        ?.toString()
        .padStart(2, "0");
    }
    const year = getInputElementByField("cc-exp-year", this);
    // If the expiration year element is an input,
    // then we examine any placeholder to see if we should format the expiration year
    // as a zero padded string in order to autofill correctly.
    if (year) {
      const placeholder = year.placeholder;

      // Checks for 'YY'|'AA'|'JJ'|'RR' placeholder and converts the year to a two digit string using the last two digits.
      const result = /\b(yy|aa|jj|rr)\b/i.test(placeholder);
      if (result) {
        profile["cc-exp-year-formatted"] = profile["cc-exp-year"]
          ?.toString()
          .substring(2);
      }
    }
  }

  /**
   * Handles credit card name transformation when the name exists in
   * the separate cc-given-name, cc-middle-name, and cc-family name fields
   *
   * @param {object} profile
   */
  creditCardNameTransformer(profile) {
    const name = profile["cc-name"];
    if (!name) {
      return;
    }

    const given = this.getFieldDetailByName("cc-given-name");
    const middle = this.getFieldDetailByName("cc-middle-name");
    const family = this.getFieldDetailByName("cc-family-name");
    if (given || middle || family) {
      const nameParts = lazy.FormAutofillNameUtils.splitName(name);
      if (given && nameParts.given) {
        profile["cc-given-name"] = nameParts.given;
      }
      if (middle && nameParts.middle) {
        profile["cc-middle-name"] = nameParts.middle;
      }
      if (family && nameParts.family) {
        profile["cc-family-name"] = nameParts.family;
      }
    }
  }

  addressTransformer(profile) {
    if (profile["street-address"]) {
      // "-moz-street-address-one-line" is used by the labels in
      // ProfileAutoCompleteResult.
      profile["-moz-street-address-one-line"] =
        FormAutofillUtils.toOneLineAddress(profile["street-address"]);
      let streetAddressDetail = this.getFieldDetailByName("street-address");
      if (
        streetAddressDetail &&
        HTMLInputElement.isInstance(streetAddressDetail.element)
      ) {
        profile["street-address"] = profile["-moz-street-address-one-line"];
      }

      let waitForConcat = [];
      for (let f of ["address-line3", "address-line2", "address-line1"]) {
        waitForConcat.unshift(profile[f]);
        if (this.getFieldDetailByName(f)) {
          if (waitForConcat.length > 1) {
            profile[f] = FormAutofillUtils.toOneLineAddress(waitForConcat);
          }
          waitForConcat = [];
        }
      }
    }

    // If a house number field exists, split the address up into house number
    // and street name.
    if (this.getFieldDetailByName("address-housenumber")) {
      let address = lazy.AddressParser.parseStreetAddress(
        profile["street-address"]
      );
      if (address) {
        profile["address-housenumber"] = address.street_number;
        let field = this.getFieldDetailByName("address-line1")
          ? "address-line1"
          : "street-address";
        profile[field] = address.street_name;
      }
    }
  }

  /**
   * Replace tel with tel-national if tel violates the input element's
   * restriction.
   *
   * @param {object} profile
   *        A profile to be converted.
   */
  telTransformer(profile) {
    if (!profile.tel || !profile["tel-national"]) {
      return;
    }

    let detail = this.getFieldDetailByName("tel");
    if (!detail) {
      return;
    }

    let element = detail.element;
    let _pattern;
    let testPattern = str => {
      if (!_pattern) {
        // The pattern has to match the entire value.
        _pattern = new RegExp("^(?:" + element.pattern + ")$", "u");
      }
      return _pattern.test(str);
    };
    if (element.pattern) {
      if (testPattern(profile.tel)) {
        return;
      }
    } else if (element.maxLength) {
      if (
        detail.reason == "autocomplete" &&
        profile.tel.length <= element.maxLength
      ) {
        return;
      }
    }

    if (detail.reason != "autocomplete") {
      // Since we only target people living in US and using en-US websites in
      // MVP, it makes more sense to fill `tel-national` instead of `tel`
      // if the field is identified by heuristics and no other clues to
      // determine which one is better.
      // TODO: [Bug 1407545] This should be improved once more countries are
      // supported.
      profile.tel = profile["tel-national"];
    } else if (element.pattern) {
      if (testPattern(profile["tel-national"])) {
        profile.tel = profile["tel-national"];
      }
    } else if (element.maxLength) {
      if (profile["tel-national"].length <= element.maxLength) {
        profile.tel = profile["tel-national"];
      }
    }
  }

  /**
   *
   * @param {object} fieldDetail A fieldDetail of the related element.
   * @param {object} profile The profile to fill.
   * @returns {string} The value to fill for the given field.
   */
  getFilledValueFromProfile(fieldDetail, profile) {
    let value =
      profile[`${fieldDetail.fieldName}-formatted`] ||
      profile[fieldDetail.fieldName];

    if (fieldDetail.fieldName == "cc-number" && fieldDetail.part != null) {
      const part = fieldDetail.part;
      return value.slice((part - 1) * 4, part * 4);
    }
    return value;
  }
  /**
   * Fills the provided element with the specified value.
   *
   * @param {HTMLInputElement| HTMLSelectElement} element - The form field element to be filled.
   * @param {string} value - The value to be filled into the form field.
   */
  static fillFieldValue(element, value) {
    if (FormAutofillUtils.focusOnAutofill) {
      element.focus({ preventScroll: true });
    }
    if (HTMLInputElement.isInstance(element)) {
      element.setUserInput(value);
    } else if (HTMLSelectElement.isInstance(element)) {
      // Set the value of the select element so that web event handlers can react accordingly
      element.value = value;
      element.dispatchEvent(
        new element.ownerGlobal.Event("input", { bubbles: true })
      );
      element.dispatchEvent(
        new element.ownerGlobal.Event("change", { bubbles: true })
      );
    }
  }

  clearPreviewedFields(elementIds) {
    for (const elementId of elementIds) {
      const fieldDetail = this.getFieldDetailByElementId(elementId);
      const element = fieldDetail?.element;
      if (!element) {
        this.log.warn(fieldDetail.fieldName, "is unreachable");
        continue;
      }

      element.previewValue = "";
      if (element.autofillState == FIELD_STATES.AUTO_FILLED) {
        continue;
      }
      this.changeFieldState(fieldDetail, FIELD_STATES.NORMAL);
    }
  }

  clearFilledFields(elementIds) {
    const fieldDetails = elementIds.map(id =>
      this.getFieldDetailByElementId(id)
    );
    for (const fieldDetail of fieldDetails) {
      const element = fieldDetail?.element;
      if (!element) {
        this.log.warn(fieldDetail?.fieldName, "is unreachable");
        continue;
      }

      if (element.autofillState == FIELD_STATES.AUTO_FILLED) {
        if (HTMLInputElement.isInstance(element)) {
          element.setUserInput("");
        } else if (HTMLSelectElement.isInstance(element)) {
          // If we can't find a selected option, then we should just reset to the first option's value
          this.#resetSelectElementValue(element);
        }
      }
    }
  }

  /**
   * Resets a <select> element to its selected option or the first option if there is none selected.
   *
   * @param {HTMLElement} element
   */
  #resetSelectElementValue(element) {
    if (!element.options.length) {
      return;
    }
    const selected = [...element.options].find(option =>
      option.hasAttribute("selected")
    );
    element.value = selected ? selected.value : element.options[0].value;
    element.dispatchEvent(
      new element.ownerGlobal.Event("input", { bubbles: true })
    );
    element.dispatchEvent(
      new element.ownerGlobal.Event("change", { bubbles: true })
    );
  }

  /**
   * Return the record that is keyed by element id and value is the normalized value
   * done by computeFillingValue
   *
   * @returns {object} An object keyed by element id, and the value is
   *                   an object that includes the following properties:
   * filledState: The autofill state of the element
   * filledvalue: The value of the element
   */
  collectFormFilledData() {
    const filledData = new Map();

    for (const fieldDetail of this.fieldDetails) {
      const element = fieldDetail.element;
      filledData.set(fieldDetail.elementId, {
        filledState: element.autofillState,
        filledValue: this.computeFillingValue(fieldDetail),
      });
    }
    return filledData;
  }

  isFieldAutofillable(fieldDetail, profile) {
    if (HTMLInputElement.isInstance(fieldDetail.element)) {
      return !!profile[fieldDetail.fieldName];
    }
    return !!this.matchSelectOptions(fieldDetail, profile);
  }
}
