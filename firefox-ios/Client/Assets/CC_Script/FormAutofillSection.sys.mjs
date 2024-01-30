/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  AutofillTelemetry: "resource://autofill/AutofillTelemetry.sys.mjs",
  CreditCard: "resource://gre/modules/CreditCard.sys.mjs",
  FormAutofillNameUtils:
    "resource://gre/modules/shared/FormAutofillNameUtils.sys.mjs",
  LabelUtils: "resource://gre/modules/shared/LabelUtils.sys.mjs",
});

const { FIELD_STATES } = FormAutofillUtils;

export class FormAutofillSection {
  static SHOULD_FOCUS_ON_AUTOFILL = true;
  #focusedInput = null;

  #fieldDetails = [];

  constructor(fieldDetails, handler) {
    this.#fieldDetails = fieldDetails;

    if (!this.isValidSection()) {
      return;
    }

    this.handler = handler;
    this.filledRecordGUID = null;

    ChromeUtils.defineLazyGetter(this, "log", () =>
      FormAutofill.defineLogGetter(this, "FormAutofillHandler")
    );

    this._cacheValue = {
      allFieldNames: null,
      matchingSelectOption: null,
    };

    // Identifier used to correlate events relating to the same form
    this.flowId = Services.uuid.generateUUID().toString();
    this.log.debug(
      "Creating new credit card section with flowId =",
      this.flowId
    );
  }

  get fieldDetails() {
    return this.#fieldDetails;
  }

  /*
   * Examine the section is a valid section or not based on its fieldDetails or
   * other information. This method must be overrided.
   *
   * @returns {boolean} True for a valid section, otherwise false
   *
   */
  isValidSection() {
    throw new TypeError("isValidSection method must be overrided");
  }

  /*
   * Examine the section is an enabled section type or not based on its
   * preferences. This method must be overrided.
   *
   * @returns {boolean} True for an enabled section type, otherwise false
   *
   */
  isEnabled() {
    throw new TypeError("isEnabled method must be overrided");
  }

  /*
   * Examine the section is createable for storing the profile. This method
   * must be overrided.
   *
   * @param {Object} record The record for examining createable
   * @returns {boolean} True for the record is createable, otherwise false
   *
   */
  isRecordCreatable(record) {
    throw new TypeError("isRecordCreatable method must be overridden");
  }

  /**
   * Override this method if the profile is needed to apply some transformers.
   *
   * @param {object} profile
   *        A profile should be converted based on the specific requirement.
   */
  applyTransformers(profile) {}

  /**
   * Override this method if the profile is needed to be customized for
   * previewing values.
   *
   * @param {object} profile
   *        A profile for pre-processing before previewing values.
   */
  preparePreviewProfile(profile) {}

  /**
   * Override this method if the profile is needed to be customized for filling
   * values.
   *
   * @param {object} profile
   *        A profile for pre-processing before filling values.
   * @returns {boolean} Whether the profile should be filled.
   */
  async prepareFillingProfile(profile) {
    return true;
  }

  /**
   * Override this method if the profile is needed to be customized for filling
   * values.
   *
   * @param {object} fieldDetail A fieldDetail of the related element.
   * @param {object} profile The profile to fill.
   * @returns {string} The value to fill for the given field.
   */
  getFilledValueFromProfile(fieldDetail, profile) {
    return (
      profile[`${fieldDetail.fieldName}-formatted`] ||
      profile[fieldDetail.fieldName]
    );
  }

  /*
   * Override this method if there is any field value needs to compute for a
   * specific case. Return the original value in the default case.
   * @param {String} value
   *        The original field value.
   * @param {Object} fieldDetail
   *        A fieldDetail of the related element.
   * @param {HTMLElement} element
   *        A element for checking converting value.
   *
   * @returns {String}
   *          A string of the converted value.
   */
  computeFillingValue(value, fieldName, element) {
    return value;
  }

  set focusedInput(element) {
    this.#focusedInput = element;
  }

  getFieldDetailByElement(element) {
    return this.fieldDetails.find(detail => detail.element == element);
  }

  getFieldDetailByName(fieldName) {
    return this.fieldDetails.find(detail => detail.fieldName == fieldName);
  }

  get allFieldNames() {
    if (!this._cacheValue.allFieldNames) {
      this._cacheValue.allFieldNames = this.fieldDetails.map(
        record => record.fieldName
      );
    }
    return this._cacheValue.allFieldNames;
  }

  matchSelectOptions(profile) {
    if (!this._cacheValue.matchingSelectOption) {
      this._cacheValue.matchingSelectOption = new WeakMap();
    }

    for (const fieldName in profile) {
      const fieldDetail = this.getFieldDetailByName(fieldName);
      const element = fieldDetail?.element;

      if (!HTMLSelectElement.isInstance(element)) {
        continue;
      }

      const cache = this._cacheValue.matchingSelectOption.get(element) || {};
      const value = profile[fieldName];
      if (cache[value] && cache[value].deref()) {
        continue;
      }

      const option = FormAutofillUtils.findSelectOption(
        element,
        profile,
        fieldName
      );

      if (option) {
        cache[value] = new WeakRef(option);
        this._cacheValue.matchingSelectOption.set(element, cache);
      } else {
        if (cache[value]) {
          delete cache[value];
          this._cacheValue.matchingSelectOption.set(element, cache);
        }
        // Skip removing cc-type since this is needed for displaying the icon for credit card network
        // TODO(Bug 1874339): Cleanup transformation and normalization of data to not remove any
        // fields and be more consistent
        if (!["cc-type"].includes(fieldName)) {
          // Delete the field so the phishing hint won't treat it as a "also fill"
          // field.
          delete profile[fieldName];
        }
      }
    }
  }

  adaptFieldMaxLength(profile) {
    for (let key in profile) {
      let detail = this.getFieldDetailByName(key);
      if (!detail) {
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

  fillFieldValue(element, value) {
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

  getAdaptedProfiles(originalProfiles) {
    for (let profile of originalProfiles) {
      this.applyTransformers(profile);
    }
    return originalProfiles;
  }

  /**
   * Processes form fields that can be autofilled, and populates them with the
   * profile provided by backend.
   *
   * @param {object} profile
   *        A profile to be filled in.
   * @returns {boolean}
   *          True if successful, false if failed
   */
  async autofillFields(profile) {
    if (!this.#focusedInput) {
      throw new Error("No focused input.");
    }

    const focusedDetail = this.getFieldDetailByElement(this.#focusedInput);
    if (!focusedDetail) {
      throw new Error("No fieldDetail for the focused input.");
    }

    this.getAdaptedProfiles([profile]);
    if (!(await this.prepareFillingProfile(profile))) {
      this.log.debug("profile cannot be filled");
      return false;
    }

    this.filledRecordGUID = profile.guid;
    for (const fieldDetail of this.fieldDetails) {
      // Avoid filling field value in the following cases:
      // 1. a non-empty input field for an unfocused input
      // 2. the invalid value set
      // 3. value already chosen in select element

      const element = fieldDetail.element;
      // Skip the field if it is null or readonly or disabled
      if (!FormAutofillUtils.isFieldAutofillable(element)) {
        continue;
      }

      element.previewValue = "";
      // Bug 1687679: Since profile appears to be presentation ready data, we need to utilize the "x-formatted" field
      // that is generated when presentation ready data doesn't fit into the autofilling element.
      // For example, autofilling expiration month into an input element will not work as expected if
      // the month is less than 10, since the input is expected a zero-padded string.
      // See Bug 1722941 for follow up.
      const value = this.getFilledValueFromProfile(fieldDetail, profile);
      if (HTMLInputElement.isInstance(element) && value) {
        // For the focused input element, it will be filled with a valid value
        // anyway.
        // For the others, the fields should be only filled when their values are empty
        // or their values are equal to the site prefill value
        // or are the result of an earlier auto-fill.
        if (
          element == this.#focusedInput ||
          (element != this.#focusedInput &&
            (!element.value || element.value == element.defaultValue)) ||
          this.handler.getFilledStateByElement(element) ==
            FIELD_STATES.AUTO_FILLED
        ) {
          this.fillFieldValue(element, value);
          this.handler.changeFieldState(fieldDetail, FIELD_STATES.AUTO_FILLED);
        }
      } else if (HTMLSelectElement.isInstance(element)) {
        let cache = this._cacheValue.matchingSelectOption.get(element) || {};
        let option = cache[value] && cache[value].deref();
        if (!option) {
          continue;
        }
        // Do not change value or dispatch events if the option is already selected.
        // Use case for multiple select is not considered here.
        if (!option.selected) {
          option.selected = true;
          this.fillFieldValue(element, option.value);
        }
        // Autofill highlight appears regardless if value is changed or not
        this.handler.changeFieldState(fieldDetail, FIELD_STATES.AUTO_FILLED);
      }
    }
    this.#focusedInput.focus({ preventScroll: true });

    lazy.AutofillTelemetry.recordFormInteractionEvent("filled", this, {
      profile,
    });

    return true;
  }

  /**
   * Populates result to the preview layers with given profile.
   *
   * @param {object} profile
   *        A profile to be previewed with
   */
  previewFormFields(profile) {
    this.preparePreviewProfile(profile);

    for (const fieldDetail of this.fieldDetails) {
      let element = fieldDetail.element;
      // Skip the field if it is null or readonly or disabled
      if (!FormAutofillUtils.isFieldAutofillable(element)) {
        continue;
      }

      let value =
        profile[`${fieldDetail.fieldName}-formatted`] ||
        profile[fieldDetail.fieldName] ||
        "";
      if (HTMLSelectElement.isInstance(element)) {
        // Unlike text input, select element is always previewed even if
        // the option is already selected.
        if (value) {
          const cache =
            this._cacheValue.matchingSelectOption.get(element) ?? {};
          const option = cache[value]?.deref();
          value = option?.text ?? "";
        }
      } else if (element.value && element.value != element.defaultValue) {
        // Skip the field if the user has already entered text and that text is not the site prefilled value.
        continue;
      }
      element.previewValue = value?.toString().replaceAll("*", "•");
      this.handler.changeFieldState(
        fieldDetail,
        value ? FIELD_STATES.PREVIEW : FIELD_STATES.NORMAL
      );
    }
  }

  /**
   * Clear a previously autofilled field in this section
   */
  clearFilled(fieldDetail) {
    lazy.AutofillTelemetry.recordFormInteractionEvent("filled_modified", this, {
      fieldName: fieldDetail.fieldName,
    });

    let isAutofilled = false;
    const dimFieldDetails = [];
    for (const fieldDetail of this.fieldDetails) {
      const element = fieldDetail.element;

      if (HTMLSelectElement.isInstance(element)) {
        // Dim fields are those we don't attempt to revert their value
        // when clear the target set, such as <select>.
        dimFieldDetails.push(fieldDetail);
      } else {
        isAutofilled |=
          this.handler.getFilledStateByElement(element) ==
          FIELD_STATES.AUTO_FILLED;
      }
    }
    if (!isAutofilled) {
      // Restore the dim fields to initial state as well once we knew
      // that user had intention to clear the filled form manually.
      for (const fieldDetail of dimFieldDetails) {
        // If we can't find a selected option, then we should just reset to the first option's value
        let element = fieldDetail.element;
        this._resetSelectElementValue(element);
        this.handler.changeFieldState(fieldDetail, FIELD_STATES.NORMAL);
      }
      this.filledRecordGUID = null;
    }
  }

  /**
   * Clear preview text and background highlight of all fields.
   */
  clearPreviewedFormFields() {
    this.log.debug("clear previewed fields");

    for (const fieldDetail of this.fieldDetails) {
      let element = fieldDetail.element;
      if (!element) {
        this.log.warn(fieldDetail.fieldName, "is unreachable");
        continue;
      }

      element.previewValue = "";

      // We keep the state if this field has
      // already been auto-filled.
      if (
        this.handler.getFilledStateByElement(element) ==
        FIELD_STATES.AUTO_FILLED
      ) {
        continue;
      }

      this.handler.changeFieldState(fieldDetail, FIELD_STATES.NORMAL);
    }
  }

  /**
   * Clear value and highlight style of all filled fields.
   */
  clearPopulatedForm() {
    for (let fieldDetail of this.fieldDetails) {
      let element = fieldDetail.element;
      if (!element) {
        this.log.warn(fieldDetail.fieldName, "is unreachable");
        continue;
      }

      if (
        this.handler.getFilledStateByElement(element) ==
        FIELD_STATES.AUTO_FILLED
      ) {
        if (HTMLInputElement.isInstance(element)) {
          element.setUserInput("");
        } else if (HTMLSelectElement.isInstance(element)) {
          // If we can't find a selected option, then we should just reset to the first option's value
          this._resetSelectElementValue(element);
        }
      }
    }
  }

  resetFieldStates() {
    for (const fieldDetail of this.fieldDetails) {
      const element = fieldDetail.element;
      element.removeEventListener("input", this, { mozSystemGroup: true });
      this.handler.changeFieldState(fieldDetail, FIELD_STATES.NORMAL);
    }
    this.filledRecordGUID = null;
  }

  isFilled() {
    return !!this.filledRecordGUID;
  }

  /**
   *  Condenses multiple credit card number fields into one fieldDetail
   *  in order to submit the credit card record correctly.
   *
   * @param {Array.<object>} condensedDetails
   *  An array of fieldDetails
   * @memberof FormAutofillSection
   */
  _condenseMultipleCCNumberFields(condensedDetails) {
    let countOfCCNumbers = 0;
    // We ignore the cases where there are more than or less than four credit card number
    // fields in a form as this is not a valid case for filling the credit card number.
    for (let i = condensedDetails.length - 1; i >= 0; i--) {
      if (condensedDetails[i].fieldName == "cc-number") {
        countOfCCNumbers++;
        if (countOfCCNumbers == 4) {
          countOfCCNumbers = 0;
          condensedDetails[i].fieldValue =
            condensedDetails[i].element?.value +
            condensedDetails[i + 1].element?.value +
            condensedDetails[i + 2].element?.value +
            condensedDetails[i + 3].element?.value;
          condensedDetails.splice(i + 1, 3);
        }
      } else {
        countOfCCNumbers = 0;
      }
    }
  }
  /**
   * Return the record that is converted from `fieldDetails` and only valid
   * form record is included.
   *
   * @returns {object | null}
   *          A record object consists of three properties:
   *            - guid: The id of the previously-filled profile or null if omitted.
   *            - record: A valid record converted from details with trimmed result.
   *            - untouchedFields: Fields that aren't touched after autofilling.
   *          Return `null` for any uncreatable or invalid record.
   */
  createRecord() {
    let details = this.fieldDetails;
    if (!this.isEnabled() || !details || !details.length) {
      return null;
    }

    let data = {
      guid: this.filledRecordGUID,
      record: {},
      untouchedFields: [],
      section: this,
    };
    if (this.flowId) {
      data.flowId = this.flowId;
    }
    let condensedDetails = this.fieldDetails;

    // TODO: This is credit card specific code...
    this._condenseMultipleCCNumberFields(condensedDetails);

    condensedDetails.forEach(detail => {
      const element = detail.element;
      // Remove the unnecessary spaces
      let value = detail.fieldValue ?? (element && element.value.trim());
      value = this.computeFillingValue(value, detail, element);

      if (!value || value.length > FormAutofillUtils.MAX_FIELD_VALUE_LENGTH) {
        // Keep the property and preserve more information for updating
        data.record[detail.fieldName] = "";
        return;
      }

      data.record[detail.fieldName] = value;

      if (
        this.handler.getFilledStateByElement(element) ==
        FIELD_STATES.AUTO_FILLED
      ) {
        data.untouchedFields.push(detail.fieldName);
      }
    });

    const telFields = this.fieldDetails.filter(
      f => FormAutofillUtils.getCategoryFromFieldName(f.fieldName) == "tel"
    );
    if (
      telFields.length &&
      telFields.every(f => data.untouchedFields.includes(f.fieldName))
    ) {
      // No need to verify it if none of related fields are modified after autofilling.
      if (!data.untouchedFields.includes("tel")) {
        data.untouchedFields.push("tel");
      }
    }

    if (!this.isRecordCreatable(data.record)) {
      return null;
    }

    return data;
  }

  /**
   * Resets a <select> element to its selected option or the first option if there is none selected.
   *
   * @param {HTMLElement} element
   * @memberof FormAutofillSection
   */
  _resetSelectElementValue(element) {
    if (!element.options.length) {
      return;
    }
    let selected = [...element.options].find(option =>
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
}

export class FormAutofillAddressSection extends FormAutofillSection {
  constructor(fieldDetails, handler) {
    super(fieldDetails, handler);

    if (!this.isValidSection()) {
      return;
    }

    this._cacheValue.oneLineStreetAddress = null;

    lazy.AutofillTelemetry.recordDetectedSectionCount(this);
    lazy.AutofillTelemetry.recordFormInteractionEvent("detected", this);
  }

  isValidSection() {
    const fields = new Set(this.fieldDetails.map(f => f.fieldName));
    return fields.size >= FormAutofillUtils.AUTOFILL_FIELDS_THRESHOLD;
  }

  isEnabled() {
    return FormAutofill.isAutofillAddressesEnabled;
  }

  isRecordCreatable(record) {
    const country = FormAutofillUtils.identifyCountryCode(
      record.country || record["country-name"]
    );
    if (
      country &&
      !FormAutofill.isAutofillAddressesAvailableInCountry(country)
    ) {
      // We don't want to save data in the wrong fields due to not having proper
      // heuristic regexes in countries we don't yet support.
      this.log.warn(
        "isRecordCreatable: Country not supported:",
        record.country
      );
      return false;
    }

    // Multiple name or tel fields are treat as 1 field while countng whether
    // the number of fields exceed the valid address secton threshold
    const categories = Object.entries(record)
      .filter(e => !!e[1])
      .map(e => FormAutofillUtils.getCategoryFromFieldName(e[0]));

    return (
      categories.reduce(
        (acc, category) =>
          ["name", "tel"].includes(category) && acc.includes(category)
            ? acc
            : [...acc, category],
        []
      ).length >= FormAutofillUtils.AUTOFILL_FIELDS_THRESHOLD
    );
  }

  _getOneLineStreetAddress(address) {
    if (!this._cacheValue.oneLineStreetAddress) {
      this._cacheValue.oneLineStreetAddress = {};
    }
    if (!this._cacheValue.oneLineStreetAddress[address]) {
      this._cacheValue.oneLineStreetAddress[address] =
        FormAutofillUtils.toOneLineAddress(address);
    }
    return this._cacheValue.oneLineStreetAddress[address];
  }

  addressTransformer(profile) {
    if (profile["street-address"]) {
      // "-moz-street-address-one-line" is used by the labels in
      // ProfileAutoCompleteResult.
      profile["-moz-street-address-one-line"] = this._getOneLineStreetAddress(
        profile["street-address"]
      );
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

  /*
   * Apply all address related transformers.
   *
   * @param {Object} profile
   *        A profile for adjusting address related value.
   * @override
   */
  applyTransformers(profile) {
    this.addressTransformer(profile);
    this.telTransformer(profile);
    this.matchSelectOptions(profile);
    this.adaptFieldMaxLength(profile);
  }

  computeFillingValue(value, fieldDetail, element) {
    // Try to abbreviate the value of select element.
    if (
      fieldDetail.fieldName == "address-level1" &&
      HTMLSelectElement.isInstance(element)
    ) {
      // Don't save the record when the option value is empty *OR* there
      // are multiple options being selected. The empty option is usually
      // assumed to be default along with a meaningless text to users.
      if (!value || element.selectedOptions.length != 1) {
        // Keep the property and preserve more information for address updating
        value = "";
      } else {
        let text = element.selectedOptions[0].text.trim();
        value =
          FormAutofillUtils.getAbbreviatedSubregionName([value, text]) || text;
      }
    }
    return value;
  }
}

export class FormAutofillCreditCardSection extends FormAutofillSection {
  /**
   * Credit Card Section Constructor
   *
   * @param {Array<FieldDetails>} fieldDetails
   *        The fieldDetail objects for the fields in this section
   * @param {Object<FormAutofillHandler>} handler
   *        The handler responsible for this section
   */
  constructor(fieldDetails, handler) {
    super(fieldDetails, handler);

    if (!this.isValidSection()) {
      return;
    }

    lazy.AutofillTelemetry.recordDetectedSectionCount(this);
    lazy.AutofillTelemetry.recordFormInteractionEvent("detected", this);

    // Check whether the section is in an <iframe>; and, if so,
    // watch for the <iframe> to pagehide.
    if (handler.window.location != handler.window.parent?.location) {
      this.log.debug(
        "Credit card form is in an iframe -- watching for pagehide",
        fieldDetails
      );
      handler.window.addEventListener(
        "pagehide",
        this._handlePageHide.bind(this)
      );
    }
  }

  _handlePageHide(event) {
    this.handler.window.removeEventListener(
      "pagehide",
      this._handlePageHide.bind(this)
    );
    this.log.debug("Credit card subframe is pagehideing", this.handler.form);

    const formSubmissionReason =
      FormAutofillUtils.FORM_SUBMISSION_REASON.IFRAME_PAGEHIDE;
    this.handler.onFormSubmitted(formSubmissionReason);
  }

  /**
   * Determine whether a set of cc fields identified by our heuristics form a
   * valid credit card section.
   * There are 4 different cases when a field is considered a credit card field
   * 1. Identified by autocomplete attribute. ex <input autocomplete="cc-number">
   * 2. Identified by fathom and fathom is pretty confident (when confidence
   *    value is higher than `highConfidenceThreshold`)
   * 3. Identified by fathom. Confidence value is between `fathom.confidenceThreshold`
   *    and `fathom.highConfidenceThreshold`
   * 4. Identified by regex-based heurstic. There is no confidence value in thise case.
   *
   * A form is considered a valid credit card form when one of the following condition
   * is met:
   * A. One of the cc field is identified by autocomplete (case 1)
   * B. One of the cc field is identified by fathom (case 2 or 3), and there is also
   *    another cc field found by any of our heuristic (case 2, 3, or 4)
   * C. Only one cc field is found in the section, but fathom is very confident (Case 2).
   *    Currently we add an extra restriction to this rule to decrease the false-positive
   *    rate. See comments below for details.
   *
   * @returns {boolean} True for a valid section, otherwise false
   */
  isValidSection() {
    let ccNumberDetail = null;
    let ccNameDetail = null;
    let ccExpiryDetail = null;

    for (let detail of this.fieldDetails) {
      switch (detail.fieldName) {
        case "cc-number":
          ccNumberDetail = detail;
          break;
        case "cc-name":
        case "cc-given-name":
        case "cc-additional-name":
        case "cc-family-name":
          ccNameDetail = detail;
          break;
        case "cc-exp":
        case "cc-exp-month":
        case "cc-exp-year":
          ccExpiryDetail = detail;
          break;
      }
    }

    // Condition A. Always trust autocomplete attribute. A section is considered a valid
    // cc section as long as a field has autocomplete=cc-number, cc-name or cc-exp*
    if (
      ccNumberDetail?.reason == "autocomplete" ||
      ccNameDetail?.reason == "autocomplete" ||
      ccExpiryDetail?.reason == "autocomplete"
    ) {
      return true;
    }

    // Condition B. One of the field is identified by fathom, if this section also
    // contains another cc field found by our heuristic (Case 2, 3, or 4), we consider
    // this section a valid credit card seciton
    if (ccNumberDetail?.reason == "fathom") {
      if (ccNameDetail || ccExpiryDetail) {
        return true;
      }
    } else if (ccNameDetail?.reason == "fathom") {
      if (ccNumberDetail || ccExpiryDetail) {
        return true;
      }
    }

    // Condition C.
    let highConfidenceThreshold =
      FormAutofillUtils.ccFathomHighConfidenceThreshold;
    let highConfidenceField;
    if (ccNumberDetail?.confidence > highConfidenceThreshold) {
      highConfidenceField = ccNumberDetail;
    } else if (ccNameDetail?.confidence > highConfidenceThreshold) {
      highConfidenceField = ccNameDetail;
    }
    if (highConfidenceField) {
      // Temporarily add an addtional "the field is the only visible input" constraint
      // when determining whether a form has only a high-confidence cc-* field a valid
      // credit card section. We can remove this restriction once we are confident
      // about only using fathom.
      const element = highConfidenceField.element;
      const root = element.form || element.ownerDocument;
      const inputs = root.querySelectorAll("input:not([type=hidden])");
      if (inputs.length == 1 && inputs[0] == element) {
        return true;
      }
    }

    return false;
  }

  isEnabled() {
    return FormAutofill.isAutofillCreditCardsEnabled;
  }

  isRecordCreatable(record) {
    return (
      record["cc-number"] && FormAutofillUtils.isCCNumber(record["cc-number"])
    );
  }

  /**
   * Handles credit card expiry date transformation when
   * the expiry date exists in a cc-exp field.
   *
   * @param {object} profile
   * @memberof FormAutofillCreditCardSection
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
    if (element.tagName == "INPUT") {
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
      if (element.previousElementSibling?.tagName == "LABEL") {
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
   * @memberof FormAutofillCreditCardSection
   */
  creditCardExpMonthAndYearTransformer(profile) {
    const getInputElementByField = (field, self) => {
      if (!field) {
        return null;
      }
      let detail = self.getFieldDetailByName(field);
      if (!detail) {
        return null;
      }
      let element = detail.element;
      return element.tagName === "INPUT" ? element : null;
    };
    let month = getInputElementByField("cc-exp-month", this);
    if (month) {
      // Transform the expiry month to MM since this is a common format needed for filling.
      profile["cc-exp-month-formatted"] = profile["cc-exp-month"]
        ?.toString()
        .padStart(2, "0");
    }
    let year = getInputElementByField("cc-exp-year", this);
    // If the expiration year element is an input,
    // then we examine any placeholder to see if we should format the expiration year
    // as a zero padded string in order to autofill correctly.
    if (year) {
      let placeholder = year.placeholder;

      // Checks for 'YY'|'AA'|'JJ'|'RR' placeholder and converts the year to a two digit string using the last two digits.
      let result = /\b(yy|aa|jj|rr)\b/i.test(placeholder);
      if (result) {
        profile["cc-exp-year-formatted"] = profile["cc-exp-year"]
          .toString()
          .substring(2);
      }
    }
  }

  /**
   * Handles credit card name transformation when the name exists in
   * the separate cc-given-name, cc-middle-name, and cc-family name fields
   *
   * @param {object} profile
   * @memberof FormAutofillCreditCardSection
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

  async _decrypt(cipherText, reauth) {
    // Get the window for the form field.
    let window;
    for (let fieldDetail of this.fieldDetails) {
      let element = fieldDetail.element;
      if (element) {
        window = element.ownerGlobal;
        break;
      }
    }
    if (!window) {
      return null;
    }

    let actor = window.windowGlobalChild.getActor("FormAutofill");
    return actor.sendQuery("FormAutofill:GetDecryptedString", {
      cipherText,
      reauth,
    });
  }

  /*
   * Apply all credit card related transformers.
   *
   * @param {Object} profile
   *        A profile for adjusting credit card related value.
   * @override
   */
  applyTransformers(profile) {
    // The matchSelectOptions transformer must be placed after the expiry transformers.
    // This ensures that the expiry value that is cached in the matchSelectOptions
    // matches the expiry value that is stored in the profile ensuring that autofill works
    // correctly when dealing with option elements.
    this.creditCardExpiryDateTransformer(profile);
    this.creditCardExpMonthAndYearTransformer(profile);
    this.creditCardNameTransformer(profile);
    this.matchSelectOptions(profile);
    this.adaptFieldMaxLength(profile);
  }

  getFilledValueFromProfile(fieldDetail, profile) {
    const value = super.getFilledValueFromProfile(fieldDetail, profile);
    if (fieldDetail.fieldName == "cc-number" && fieldDetail.part != null) {
      const part = fieldDetail.part;
      return value.slice((part - 1) * 4, part * 4);
    }
    return value;
  }

  computeFillingValue(value, fieldDetail, element) {
    if (
      fieldDetail.fieldName != "cc-type" ||
      !HTMLSelectElement.isInstance(element)
    ) {
      return value;
    }

    if (lazy.CreditCard.isValidNetwork(value)) {
      return value;
    }

    // Don't save the record when the option value is empty *OR* there
    // are multiple options being selected. The empty option is usually
    // assumed to be default along with a meaningless text to users.
    if (value && element.selectedOptions.length == 1) {
      let selectedOption = element.selectedOptions[0];
      let networkType =
        lazy.CreditCard.getNetworkFromName(selectedOption.text) ??
        lazy.CreditCard.getNetworkFromName(selectedOption.value);
      if (networkType) {
        return networkType;
      }
    }
    // If we couldn't match the value to any network, we'll
    // strip this field when submitting.
    return value;
  }

  /**
   * Customize for previewing profile
   *
   * @param {object} profile
   *        A profile for pre-processing before previewing values.
   * @override
   */
  preparePreviewProfile(profile) {
    // Always show the decrypted credit card number when Master Password is
    // disabled.
    if (profile["cc-number-decrypted"]) {
      profile["cc-number"] = profile["cc-number-decrypted"];
    } else if (!profile["cc-number"].startsWith("****")) {
      // Show the previewed credit card as "**** 4444" which is
      // needed when a credit card number field has a maxlength of four.
      profile["cc-number"] = "****" + profile["cc-number"];
    }
  }

  /**
   * Customize for filling profile
   *
   * @param {object} profile
   *        A profile for pre-processing before filling values.
   * @returns {boolean} Whether the profile should be filled.
   * @override
   */
  async prepareFillingProfile(profile) {
    // Prompt the OS login dialog to get the decrypted credit card number.
    if (profile["cc-number-encrypted"]) {
      const promptMessage = FormAutofillUtils.reauthOSPromptMessage(
        "autofill-use-payment-method-os-prompt-macos",
        "autofill-use-payment-method-os-prompt-windows",
        "autofill-use-payment-method-os-prompt-other"
      );
      let decrypted = await this._decrypt(
        profile["cc-number-encrypted"],
        promptMessage
      );

      if (!decrypted) {
        // Early return if the decrypted is empty or undefined
        return false;
      }

      profile["cc-number"] = decrypted;
    }
    return true;
  }
}
