/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  AutofillTelemetry: "resource://gre/modules/shared/AutofillTelemetry.sys.mjs",
  FormAutofillUtils: "resource://gre/modules/shared/FormAutofillUtils.sys.mjs",
  FormAutofill: "resource://autofill/FormAutofill.sys.mjs",
  OSKeyStore: "resource://gre/modules/OSKeyStore.sys.mjs",
});

/**
 * To help us classify sections, we want to know what fields can appear
 * multiple times in a row.
 * Such fields, like `address-line{X}`, should not break sections.
 */
const MULTI_FIELD_NAMES = [
  "address-level3",
  "address-level2",
  "address-level1",
  "tel",
  "postal-code",
  "email",
  "street-address",
];

class FormSection {
  static ADDRESS = "address";
  static CREDIT_CARD = "creditCard";

  #fieldDetails = [];

  #name = "";

  constructor(fieldDetails) {
    if (!fieldDetails.length) {
      throw new TypeError("A section should contain at least one field");
    }

    fieldDetails.forEach(field => this.addField(field));

    const fieldName = fieldDetails[0].fieldName;
    if (lazy.FormAutofillUtils.isAddressField(fieldName)) {
      this.type = FormSection.ADDRESS;
    } else if (lazy.FormAutofillUtils.isCreditCardField(fieldName)) {
      this.type = FormSection.CREDIT_CARD;
    } else {
      throw new Error("Unknown field type to create a section.");
    }
  }

  get fieldDetails() {
    return this.#fieldDetails;
  }

  get name() {
    return this.#name;
  }

  addField(fieldDetail) {
    this.#name ||= fieldDetail.sectionName;
    this.#fieldDetails.push(fieldDetail);
  }
}

export class FormAutofillSection {
  /**
   * Record information for fields that are in this section
   */
  #fieldDetails = [];

  constructor(fieldDetails) {
    this.#fieldDetails = fieldDetails;

    ChromeUtils.defineLazyGetter(this, "log", () =>
      lazy.FormAutofill.defineLogGetter(this, "FormAutofillSection")
    );

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

  get allFieldNames() {
    return this.fieldDetails.map(field => field.fieldName);
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
   * @param {Object} _record The record for examining createable
   * @returns {boolean} True for the record is createable, otherwise false
   *
   */
  isRecordCreatable(_record) {
    throw new TypeError("isRecordCreatable method must be overridden");
  }

  /**
   * Override this method if the profile is needed to be customized for
   * previewing values.
   *
   * @param {object} _profile
   *        A profile for pre-processing before previewing values.
   * @returns {boolean} Whether the profile should be previewed.
   */
  preparePreviewProfile(_profile) {
    return true;
  }

  /**
   * Override this method if the profile is needed to be customized for filling
   * values.
   *
   * @param {object} _profile
   *        A profile for pre-processing before filling values.
   * @returns {boolean} Whether the profile should be filled.
   */
  async prepareFillingProfile(_profile) {
    return true;
  }

  /**
   * The result is an array contains the sections with its belonging field details.
   *
   * @param   {Array<FieldDetails>} fieldDetails field detail array to be classified
   * @param   {boolean} ignoreInvalid
   *          True to keep invalid section in the return array. Only used by tests now.
   * @returns {Array<FormSection>} The array with the sections.
   */
  static classifySections(fieldDetails, ignoreInvalid = false) {
    const addressSections = FormAutofillSection.groupFields(
      fieldDetails.filter(f =>
        lazy.FormAutofillUtils.isAddressField(f.fieldName)
      )
    );
    const creditCardSections = FormAutofillSection.groupFields(
      fieldDetails.filter(f =>
        lazy.FormAutofillUtils.isCreditCardField(f.fieldName)
      )
    );

    const sections = [...addressSections, ...creditCardSections].sort(
      (a, b) =>
        fieldDetails.indexOf(a.fieldDetails[0]) -
        fieldDetails.indexOf(b.fieldDetails[0])
    );

    const autofillableSections = [];
    for (const section of sections) {
      if (!section.fieldDetails.length) {
        continue;
      }

      const autofillableSection =
        section.type == FormSection.ADDRESS
          ? new FormAutofillAddressSection(section.fieldDetails)
          : new FormAutofillCreditCardSection(section.fieldDetails);

      if (ignoreInvalid && !autofillableSection.isValidSection()) {
        continue;
      }

      autofillableSections.push(autofillableSection);
    }
    return autofillableSections;
  }

  /**
   * Groups fields into sections based on:
   * 1. Their `sectionName` attribute.
   * 2. Whether the section already contains a field with the same `fieldName`,
   *    If so, a new section is created.
   *
   * @param {Array} fieldDetails An array of field detail objects.
   * @returns {Array} An array of FormSection objects.
   */
  static groupFields(fieldDetails) {
    let sections = [];
    for (let i = 0; i < fieldDetails.length; i++) {
      const cur = fieldDetails[i];
      const [currentSection] = sections.slice(-1);

      // The section this field might be placed into.
      let candidateSection = null;

      // Use name group from autocomplete attribute (ex, section-xxx) to look for the section
      // we might place this field into.
      // If the field doesn't have a section name, the candidate section is the previous section.
      if (!currentSection || !cur.sectionName) {
        candidateSection = currentSection;
      } else if (cur.sectionName) {
        // If the field has a section name, the candidate section is the nearest section that
        // either shares the same name or lacks a name.
        for (let idx = sections.length - 1; idx >= 0; idx--) {
          if (!sections[idx].name || sections[idx].name == cur.sectionName) {
            candidateSection = sections[idx];
            break;
          }
        }
      }

      if (candidateSection) {
        let createNewSection = true;

        // We might create a new section instead of placing the field in the candidate section if
        // the section already has a field with the same field name.
        // We also check visibility for both the fields with the same field name because we don't
        // want to create a new section for an invisible field.
        if (
          candidateSection.fieldDetails.find(
            f => f.fieldName == cur.fieldName && f.isVisible && cur.isVisible
          )
        ) {
          // For some field type, it is common to have multiple fields in one section, for example,
          // email. In that case, we will not create a new section even when the candidate section
          // already has a field with the same field name.
          const [last] = candidateSection.fieldDetails.slice(-1);
          if (last.fieldName == cur.fieldName) {
            if (
              MULTI_FIELD_NAMES.includes(cur.fieldName) ||
              (last.part && last.part + 1 == cur.part)
            ) {
              createNewSection = false;
            }
          }
        } else {
          // The field doesn't exist in the candidate section, add it.
          createNewSection = false;
        }

        if (!createNewSection) {
          candidateSection.addField(fieldDetails[i]);
          continue;
        }
      }

      // Create a new section
      sections.push(new FormSection([fieldDetails[i]]));
    }

    return sections;
  }

  /**
   * Return the record that is converted from the element's value.
   * The `valueByElementId` is passed by the child process.
   *
   * @returns {object} object keyed by field name, and values are field values.
   */
  createRecord(formFilledData) {
    if (!this.fieldDetails.length) {
      return {};
    }

    const data = {
      flowId: this.flowId,
      record: {},
    };

    for (const detail of this.fieldDetails) {
      // Do not save security code.
      if (detail.fieldName == "cc-csc") {
        continue;
      }
      const { filledValue } = formFilledData.get(detail.elementId) ?? {};

      if (
        !filledValue ||
        filledValue.length > lazy.FormAutofillUtils.MAX_FIELD_VALUE_LENGTH
      ) {
        // Keep the property and preserve more information for updating
        data.record[detail.fieldName] = "";
      } else if (detail.part > 1) {
        // If there are multiple parts for the same field, concatenate the values.
        // This is now used in cases where the credit card number field
        // is split into multiple fields.
        data.record[detail.fieldName] += filledValue;
      } else {
        data.record[detail.fieldName] = filledValue;
      }
    }

    if (!this.isRecordCreatable(data.record)) {
      return null;
    }

    return data;
  }

  /**
   * Heuristics to determine which fields to autofill when a section contains
   * multiple fields of the same type.
   */
  getAutofillFields() {
    return this.fieldDetails.filter(fieldDetail => {
      // We don't save security code, but if somehow the profile has securty code,
      // make sure we don't autofill it.
      if (fieldDetail.fieldName == "cc-csc") {
        return false;
      }

      // When both visible and invisible elements exist, we only autofill the
      // visible element.
      if (!fieldDetail.isVisible) {
        return !this.fieldDetails.some(
          field => field.fieldName == fieldDetail.fieldName && field.isVisible
        );
      }
      return true;
    });
  }

  /*
   * For telemetry
   */
  onDetected() {
    if (!this.isValidSection()) {
      return;
    }

    lazy.AutofillTelemetry.recordDetectedSectionCount(this.fieldDetails);
    lazy.AutofillTelemetry.recordFormInteractionEvent(
      "detected",
      this.flowId,
      this.fieldDetails
    );
  }

  onPopupOpened(elementId) {
    const fieldDetail = this.getFieldDetailByElementId(elementId);
    lazy.AutofillTelemetry.recordFormInteractionEvent(
      "popup_shown",
      this.flowId,
      [fieldDetail]
    );
  }

  onFilled(filledResult) {
    lazy.AutofillTelemetry.recordFormInteractionEvent(
      "filled",
      this.flowId,
      this.fieldDetails,
      filledResult
    );
  }

  onFilledModified(elementId) {
    const fieldDetail = this.getFieldDetailByElementId(elementId);
    lazy.AutofillTelemetry.recordFormInteractionEvent(
      "filled_modified",
      this.flowId,
      [fieldDetail]
    );
  }

  onSubmitted(formFilledData) {
    this.submitted = true;

    lazy.AutofillTelemetry.recordSubmittedSectionCount(this.fieldDetails, 1);
    lazy.AutofillTelemetry.recordFormInteractionEvent(
      "submitted",
      this.flowId,
      this.fieldDetails,
      formFilledData
    );
  }

  onCleared(elementId) {
    const fieldDetail = this.getFieldDetailByElementId(elementId);
    lazy.AutofillTelemetry.recordFormInteractionEvent("cleared", this.flowId, [
      fieldDetail,
    ]);
  }

  /**
   * Utility functions
   */
  getFieldDetailByElementId(elementId) {
    return this.fieldDetails.find(detail => detail.elementId == elementId);
  }

  /**
   * Groups an array of field details by their browsing context IDs.
   *
   * @param {Array} fieldDetails
   *        Array of fieldDetails object
   *
   * @returns {object}
   *        An object keyed by BrowsingContext Id, value is an array that
   *        contains all fieldDetails with the same BrowsingContext id.
   */
  static groupFieldDetailsByBrowsingContext(fieldDetails) {
    const detailsByBC = {};
    for (const fieldDetail of fieldDetails) {
      const bcid = fieldDetail.browsingContextId;
      if (detailsByBC[bcid]) {
        detailsByBC[bcid].push(fieldDetail);
      } else {
        detailsByBC[bcid] = [fieldDetail];
      }
    }
    return detailsByBC;
  }
}

export class FormAutofillAddressSection extends FormAutofillSection {
  isValidSection() {
    const fields = new Set(this.fieldDetails.map(f => f.fieldName));
    return fields.size >= lazy.FormAutofillUtils.AUTOFILL_FIELDS_THRESHOLD;
  }

  isEnabled() {
    return lazy.FormAutofill.isAutofillAddressesEnabled;
  }

  isRecordCreatable(record) {
    const country = lazy.FormAutofillUtils.identifyCountryCode(
      record.country || record["country-name"]
    );
    if (
      country &&
      !lazy.FormAutofill.isAutofillAddressesAvailableInCountry(country)
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
      .map(e => lazy.FormAutofillUtils.getCategoryFromFieldName(e[0]));

    return (
      categories.reduce(
        (acc, category) =>
          ["name", "tel"].includes(category) && acc.includes(category)
            ? acc
            : [...acc, category],
        []
      ).length >= lazy.FormAutofillUtils.AUTOFILL_FIELDS_THRESHOLD
    );
  }
}

export class FormAutofillCreditCardSection extends FormAutofillSection {
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
    if (
      ccNumberDetail?.isOnlyVisibleFieldWithHighConfidence ||
      ccNameDetail?.isOnlyVisibleFieldWithHighConfidence
    ) {
      return true;
    }

    return false;
  }

  isEnabled() {
    return lazy.FormAutofill.isAutofillCreditCardsEnabled;
  }

  isRecordCreatable(record) {
    return (
      record["cc-number"] &&
      lazy.FormAutofillUtils.isCCNumber(record["cc-number"])
    );
  }

  /**
   * Customize for previewing profile
   *
   * @param {object} profile
   *        A profile for pre-processing before previewing values.
   * @returns {boolean} Whether the profile should be filled.
   * @override
   */
  preparePreviewProfile(profile) {
    if (!profile) {
      return true;
    }

    // Always show the decrypted credit card number when Master Password is
    // disabled.
    if (profile["cc-number-decrypted"]) {
      profile["cc-number"] = profile["cc-number-decrypted"];
    } else if (!profile["cc-number"].startsWith("****")) {
      // Show the previewed credit card as "**** 4444" which is
      // needed when a credit card number field has a maxlength of four.
      profile["cc-number"] = "****" + profile["cc-number"];
    }

    return true;
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
      const promptMessage = lazy.FormAutofillUtils.reauthOSPromptMessage(
        "autofill-use-payment-method-os-prompt-macos",
        "autofill-use-payment-method-os-prompt-windows",
        "autofill-use-payment-method-os-prompt-other"
      );
      const decrypted = await this.getDecryptedString(
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

  async getDecryptedString(cipherText, reauth) {
    if (
      !lazy.FormAutofillUtils.getOSAuthEnabled(
        lazy.FormAutofill.AUTOFILL_CREDITCARDS_REAUTH_PREF
      )
    ) {
      this.log.debug("Reauth is disabled");
      reauth = false;
    }
    let string;
    try {
      string = await lazy.OSKeyStore.decrypt(cipherText, reauth);
    } catch (e) {
      if (e.result != Cr.NS_ERROR_ABORT) {
        throw e;
      }
      this.log.warn("User canceled encryption login");
    }
    return string;
  }
}
