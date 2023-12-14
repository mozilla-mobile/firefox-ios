/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  FormAutofillAddressSection:
    "resource://gre/modules/shared/FormAutofillSection.sys.mjs",
  FormAutofillCreditCardSection:
    "resource://gre/modules/shared/FormAutofillSection.sys.mjs",
  FormAutofillHeuristics:
    "resource://gre/modules/shared/FormAutofillHeuristics.sys.mjs",
  FormLikeFactory: "resource://gre/modules/FormLikeFactory.sys.mjs",
  FormSection: "resource://gre/modules/shared/FormAutofillHeuristics.sys.mjs",
});

const { FIELD_STATES } = FormAutofillUtils;

/**
 * Handles profile autofill for a DOM Form element.
 */
export class FormAutofillHandler {
  // The window to which this form belongs
  window = null;

  // A WindowUtils reference of which Window the form belongs
  winUtils = null;

  // DOM Form element to which this object is attached
  form = null;

  // An array of section that are found in this form
  sections = [];

  // The section contains the focused input
  #focusedSection = null;

  // Caches the element to section mapping
  #cachedSectionByElement = new WeakMap();

  // Keeps track of filled state for all identified elements
  #filledStateByElement = new WeakMap();
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
  fieldDetails = null;

  /**
   * Initialize the form from `FormLike` object to handle the section or form
   * operations.
   *
   * @param {FormLike} form Form that need to be auto filled
   * @param {Function} onFormSubmitted Function that can be invoked
   *                   to simulate form submission. Function is passed
   *                   four arguments: (1) a FormLike for the form being
   *                   submitted, (2) the reason for infering the form
   *                   submission (3) the corresponding Window, and (4)
   *                   the responsible FormAutofillHandler.
   * @param {Function} onAutofillCallback Function that can be invoked
   *                   when we want to suggest autofill on a form.
   */
  constructor(form, onFormSubmitted = () => {}, onAutofillCallback = () => {}) {
    this._updateForm(form);

    this.window = this.form.rootElement.ownerGlobal;
    this.winUtils = this.window.windowUtils;

    // Enum for form autofill MANUALLY_MANAGED_STATES values
    this.FIELD_STATE_ENUM = {
      // not themed
      [FIELD_STATES.NORMAL]: null,
      // highlighted
      [FIELD_STATES.AUTO_FILLED]: "autofill",
      // highlighted && grey color text
      [FIELD_STATES.PREVIEW]: "-moz-autofill-preview",
    };

    /**
     * This function is used if the form handler (or one of its sections)
     * determines that it needs to act as if the form had been submitted.
     */
    this.onFormSubmitted = formSubmissionReason => {
      onFormSubmitted(this.form, formSubmissionReason, this.window, this);
    };

    this.onAutofillCallback = onAutofillCallback;

    ChromeUtils.defineLazyGetter(this, "log", () =>
      FormAutofill.defineLogGetter(this, "FormAutofillHandler")
    );
  }

  handleEvent(event) {
    switch (event.type) {
      case "input": {
        if (!event.isTrusted) {
          return;
        }
        const target = event.target;
        const targetFieldDetail = this.getFieldDetailByElement(target);
        const isCreditCardField = FormAutofillUtils.isCreditCardField(
          targetFieldDetail.fieldName
        );

        // If the user manually blanks a credit card field, then
        // we want the popup to be activated.
        if (
          !HTMLSelectElement.isInstance(target) &&
          isCreditCardField &&
          target.value === ""
        ) {
          this.onAutofillCallback();
        }

        if (this.getFilledStateByElement(target) == FIELD_STATES.NORMAL) {
          return;
        }

        this.changeFieldState(targetFieldDetail, FIELD_STATES.NORMAL);
        const section = this.getSectionByElement(targetFieldDetail.element);
        section?.clearFilled(targetFieldDetail);
      }
    }
  }

  set focusedInput(element) {
    const section = this.getSectionByElement(element);
    if (!section) {
      return;
    }

    this.#focusedSection = section;
    this.#focusedSection.focusedInput = element;
  }

  getSectionByElement(element) {
    const section =
      this.#cachedSectionByElement.get(element) ??
      this.sections.find(s => s.getFieldDetailByElement(element));
    if (!section) {
      return null;
    }

    this.#cachedSectionByElement.set(element, section);
    return section;
  }

  getFieldDetailByElement(element) {
    for (const section of this.sections) {
      const detail = section.getFieldDetailByElement(element);
      if (detail) {
        return detail;
      }
    }
    return null;
  }

  get activeSection() {
    return this.#focusedSection;
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
        _formLike = lazy.FormLikeFactory.createFromField(element);
      }
      return _formLike;
    };

    const currentForm = element.form ?? getFormLike();
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

    this.fieldDetails = null;

    this.sections = [];
    this.#cachedSectionByElement = new WeakMap();
  }

  /**
   * Set fieldDetails from the form about fields that can be autofilled.
   *
   * @returns {Array} The valid address and credit card details.
   */
  collectFormFields(ignoreInvalid = true) {
    const sections = lazy.FormAutofillHeuristics.getFormInfo(this.form);
    const allValidDetails = [];
    for (const section of sections) {
      // We don't support csc field, so remove csc fields from section
      const fieldDetails = section.fieldDetails.filter(
        f => !["cc-csc"].includes(f.fieldName)
      );
      if (!fieldDetails.length) {
        continue;
      }

      let autofillableSection;
      if (section.type == lazy.FormSection.ADDRESS) {
        autofillableSection = new lazy.FormAutofillAddressSection(
          fieldDetails,
          this
        );
      } else {
        autofillableSection = new lazy.FormAutofillCreditCardSection(
          fieldDetails,
          this
        );
      }

      // Do not include section that is either disabled or invalid.
      // We only include invalid section for testing purpose.
      if (
        !autofillableSection.isEnabled() ||
        (ignoreInvalid && !autofillableSection.isValidSection())
      ) {
        continue;
      }

      this.sections.push(autofillableSection);
      allValidDetails.push(...autofillableSection.fieldDetails);
    }

    this.fieldDetails = allValidDetails;
    return allValidDetails;
  }

  #hasFilledSection() {
    return this.sections.some(section => section.isFilled());
  }

  getFilledStateByElement(element) {
    return this.#filledStateByElement.get(element);
  }

  /**
   * Change the state of a field to correspond with different presentations.
   *
   * @param {object} fieldDetail
   *        A fieldDetail of which its element is about to update the state.
   * @param {string} nextState
   *        Used to determine the next state
   */
  changeFieldState(fieldDetail, nextState) {
    const element = fieldDetail.element;
    if (!element) {
      this.log.warn(
        fieldDetail.fieldName,
        "is unreachable while changing state"
      );
      return;
    }
    if (!(nextState in this.FIELD_STATE_ENUM)) {
      this.log.warn(
        fieldDetail.fieldName,
        "is trying to change to an invalid state"
      );
      return;
    }

    if (this.#filledStateByElement.get(element) == nextState) {
      return;
    }

    let nextStateValue = null;
    for (const [state, mmStateValue] of Object.entries(this.FIELD_STATE_ENUM)) {
      // The NORMAL state is simply the absence of other manually
      // managed states so we never need to add or remove it.
      if (!mmStateValue) {
        continue;
      }

      if (state == nextState) {
        nextStateValue = mmStateValue;
      } else {
        this.winUtils.removeManuallyManagedState(element, mmStateValue);
      }
    }

    if (nextStateValue) {
      this.winUtils.addManuallyManagedState(element, nextStateValue);
    }

    if (nextState == FIELD_STATES.AUTO_FILLED) {
      element.addEventListener("input", this, { mozSystemGroup: true });
    }

    this.#filledStateByElement.set(element, nextState);
  }

  /**
   * Processes form fields that can be autofilled, and populates them with the
   * profile provided by backend.
   *
   * @param {object} profile
   *        A profile to be filled in.
   */
  async autofillFormFields(profile) {
    const noFilledSectionsPreviously = !this.#hasFilledSection();
    await this.activeSection.autofillFields(profile);

    const onChangeHandler = e => {
      if (!e.isTrusted) {
        return;
      }
      if (e.type == "reset") {
        this.sections.map(section => section.resetFieldStates());
      }
      // Unregister listeners once no field is in AUTO_FILLED state.
      if (!this.#hasFilledSection()) {
        this.form.rootElement.removeEventListener("input", onChangeHandler, {
          mozSystemGroup: true,
        });
        this.form.rootElement.removeEventListener("reset", onChangeHandler, {
          mozSystemGroup: true,
        });
      }
    };

    if (noFilledSectionsPreviously) {
      // Handle the highlight style resetting caused by user's correction afterward.
      this.log.debug("register change handler for filled form:", this.form);
      this.form.rootElement.addEventListener("input", onChangeHandler, {
        mozSystemGroup: true,
      });
      this.form.rootElement.addEventListener("reset", onChangeHandler, {
        mozSystemGroup: true,
      });
    }
  }

  /**
   * Collect the filled sections within submitted form and convert all the valid
   * field data into multiple records.
   *
   * @returns {object} records
   *          {Array.<Object>} records.address
   *          {Array.<Object>} records.creditCard
   */
  createRecords() {
    const records = {
      address: [],
      creditCard: [],
    };

    for (const section of this.sections) {
      const secRecord = section.createRecord();
      if (!secRecord) {
        continue;
      }
      if (section instanceof lazy.FormAutofillAddressSection) {
        records.address.push(secRecord);
      } else if (section instanceof lazy.FormAutofillCreditCardSection) {
        records.creditCard.push(secRecord);
      } else {
        throw new Error("Unknown section type");
      }
    }

    return records;
  }
}
