/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  FormAutofill: "resource://autofill/FormAutofill.sys.mjs",
  FormAutofillUtils: "resource://gre/modules/shared/FormAutofillUtils.sys.mjs",
});

// Defines template descriptors for generating elements in convertLayoutToUI.
const fieldTemplates = {
  commonAttributes(item) {
    return {
      id: item.fieldId,
      name: item.fieldId,
      required: item.required,
      value: item.value ?? "",
      // Conditionally add pattern attribute since pattern=""/false/undefined
      // results in weird behaviour.
      ...(item.pattern && { pattern: item.pattern }),
    };
  },
  input(item) {
    return {
      tag: "input",
      type: item.type ?? "text",
      ...this.commonAttributes(item),
    };
  },
  textarea(item) {
    return {
      tag: "textarea",
      ...this.commonAttributes(item),
    };
  },
  select(item) {
    return {
      tag: "select",
      children: item.options.map(({ value, text }) => ({
        tag: "option",
        selected: value === item.value,
        value,
        text,
      })),
      ...this.commonAttributes(item),
    };
  },
};

/**
 * Creates an HTML element with specified attributes and children.
 *
 * @param {string} tag - Tag name for the element to create.
 * @param {object} options - Options object containing attributes and children.
 * @param {object} options.attributes - Element's Attributes/Props (id, class, etc.)
 * @param {Array} options.children - Element's children (array of objects with tag and options).
 * @returns {HTMLElement} The newly created element.
 */
const createElement = (tag, { children = [], ...attributes }) => {
  const element = document.createElement(tag);

  for (let [attributeName, attributeValue] of Object.entries(attributes)) {
    if (attributeName in element) {
      element[attributeName] = attributeValue;
    } else {
      element.setAttribute(attributeName, attributeValue);
    }
  }

  for (let { tag: childTag, ...childRest } of children) {
    element.appendChild(createElement(childTag, childRest));
  }

  return element;
};

/**
 * Generator that creates UI elements from `fields` object, using localization from `l10nStrings`.
 *
 * @param {Array} fields - Array of objects as returned from `FormAutofillUtils.getFormLayout`.
 * @param {object} l10nStrings - Key-value pairs for field label localization.
 * @yields {HTMLElement} - A localized label element with constructed from a field.
 */
function* convertLayoutToUI(fields, l10nStrings) {
  for (const item of fields) {
    // eslint-disable-next-line no-nested-ternary
    const fieldTag = item.options
      ? "select"
      : item.multiline
        ? "textarea"
        : "input";

    const fieldUI = {
      label: {
        id: `${item.fieldId}-container`,
        class: `container ${item.newLine ? "new-line" : ""}`,
      },
      field: fieldTemplates[fieldTag](item),
      span: {
        class: "label-text",
        textContent: l10nStrings[item.l10nId] ?? "",
      },
    };

    const label = createElement("label", fieldUI.label);
    const { tag, ...rest } = fieldUI.field;
    const span = createElement("span", fieldUI.span);
    label.appendChild(span);
    const field = createElement(tag, rest);
    label.appendChild(field);
    yield label;
  }
}

/**
 * Retrieves the current form data from the current form element on the page.
 * NOTE: We are intentionally not using FormData here because on iOS we have states where
 *       selects are disabled and FormData ignores disabled elements. We want getCurrentFormData
 *       to always refelect the exact state of the form.
 *
 * @returns {object} An object containing key-value pairs of form data.
 */
export const getCurrentFormData = () => {
  const formData = {};
  for (const element of document.querySelector("form").elements) {
    formData[element.name] = element.value ?? "";
  }
  return formData;
};

/**
 * Checks if the form can be submitted based on the number of non-empty values.
 * TODO(Bug 1891734): Add address validation. Right now we don't do any validation. (2 fields mimics the old behaviour ).
 *
 * @returns {boolean} True if the form can be submitted
 */
export const canSubmitForm = () => {
  const formData = getCurrentFormData();
  const validValues = Object.values(formData).filter(Boolean);
  return validValues.length >= 2;
};

/**
 * Generates a form layout based on record data and localization strings.
 *
 * @param {HTMLFormElement} formElement - Target form element.
 * @param {object} record - Address record, includes at least country code defaulted to FormAutofill.DEFAULT_REGION.
 * @param {object} l10nStrings - Localization strings map.
 */
export const createFormLayoutFromRecord = (
  formElement,
  record = { country: lazy.FormAutofill.DEFAULT_REGION },
  l10nStrings = {}
) => {
  // Always clear select values because they are not persisted between countries.
  // For example from US with state NY, we don't want the address-level1 to be NY
  // when changing to another country that doesn't have state options
  const selects = formElement.querySelectorAll("select:not(#country)");
  for (const select of selects) {
    select.value = "";
  }

  // Get old data to persist before clearing form
  const formData = getCurrentFormData();
  record = {
    ...record,
    ...formData,
  };

  formElement.innerHTML = "";
  const fields = lazy.FormAutofillUtils.getFormLayout(record);

  const layoutGenerator = convertLayoutToUI(fields, l10nStrings);

  for (const fieldElement of layoutGenerator) {
    formElement.appendChild(fieldElement);
  }

  document.querySelector("#country").addEventListener(
    "change",
    ev =>
      // Allow some time for the user to type
      // before we set the new country and re-render
      setTimeout(() => {
        record.country = ev.target.value;
        createFormLayoutFromRecord(formElement, record, l10nStrings);
      }, 300),
    { once: true }
  );

  // Used to notify tests that the form has been updated and is ready
  window.dispatchEvent(new CustomEvent("FormReadyForTests"));
};
