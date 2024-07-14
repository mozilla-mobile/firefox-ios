/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import "resource://gre/modules/shared/Helpers.ios.mjs";
import {
  createFormLayoutFromRecord,
  getCurrentFormData,
} from "resource://gre/modules/shared/addressFormLayout.mjs";

/**
 * Expose getCurrentFormData to the window object.
 * TODO(issam): figure out why sometimes coutry code is not being passed.
 */
window.getCurrentFormData = () => {
  const country = document.querySelector("#country")?.value;
  return {country,  ...getCurrentFormData()};
};

/**
 * Sets the theme of the webview.
 * @param {Boolean} isDarkTheme - Set to true if the dark theme should be applied.
 */
const setTheme = (isDarkTheme) => {
  document.body.classList.toggle("dark", isDarkTheme);
};
window.setTheme = setTheme;

/**
 * Automatically resizes a textarea to fit its content.
 * @param {HTMLTextAreaElement} textarea - The textarea element to resize.
 * @param {Number} initialHeight - The initial height of the textarea. Default is 22.
 */
const autoResizeTextarea = (textarea, initialHeight = 22) => {
  textarea.style.height = "auto";
  const lines = textarea.value.match(/^/gm).length;
  textarea.style.height =
    lines <= 1 ? `${initialHeight}px` : `${textarea.scrollHeight}px`;
};

/**
 * Renders an address form into the webview from a record.
 *
 * @param {object} record - Address record, includes at least country code defaulted to FormAutofill.DEFAULT_REGION.
 * @param {object} l10nStrings - Localization strings map.
 * @param {boolean} isDarkTheme - Set to true if the dark theme should be applied. Default is false.
 * @param {boolean} isNewRecord - Set to true if we are creating a new record from scratch. Default is false.
 */
const init = (
  record,
  l10nStrings,
  isDarkTheme = false,
  isNewRecord = false
) => {
  setTheme(isDarkTheme);

  // Replace all "\\n" with new line character.
  for (const [key, value] of Object.entries(record)) {
    if (typeof value === "string") {
      record[key] = value.replaceAll("\\n", "\n");
    }
  }

  createFormLayoutFromRecord(
    document.querySelector("form"),
    record,
    l10nStrings
  );

  document.querySelectorAll("textarea").forEach((textarea) => {
    autoResizeTextarea(textarea);
    textarea.addEventListener("input", () => autoResizeTextarea(textarea));
  });

  // By default on init, the form is not editable.
  toggleEditMode(isNewRecord);
  if (isNewRecord || isFormValid()) {
    // setup validation for the form
    setupValidation();
  }
};
window.init = init;

/**
 * Returns true if the form is valid.
 * Checks if all fields are valid.
 */
const isFormValid = () => {
  const form = document.querySelector("form");
  const textFields = form.querySelectorAll("input, textarea");
  return [...textFields].every((element) => element.checkValidity());
};

/**
 * Create or update an error message for an input field.
 * TODO(issam): eventually errorMessage should be our own
 *              localized message ( waiting for content ).
 */
const createOrUpdateError = (inputWrapper, errorMessage) => {
  const errorTemplate = (errorMessage) =>
    `<div class="error">${errorMessage}</div>`;
  let errorElement = inputWrapper.querySelector(".error");
  if (!errorElement) {
    inputWrapper.insertAdjacentHTML("beforeend", errorTemplate(errorMessage));
    errorElement = inputWrapper.querySelector(".error");
  }
  errorElement.textContent = errorMessage ?? textField.validationMessage ?? "";
};

/**
 * Sets up validation for the form.
 * Adds error messages to the form fields that are invalid.
 */
const setupValidation = () => {
  const textFields = document.querySelectorAll("input, textarea");

  const handleValidation = (textField) => {
    const isValid = textField.checkValidity();
    const inputWrapper = textField.parentElement;

    // if element is now valid remove the error message if it exists
    if (isValid) {
      inputWrapper.querySelector(".error")?.remove();
      return;
    }

    // if element is not valid create or update the error message
    createOrUpdateError(inputWrapper, textField.validationMessage);
  };

  textFields.forEach((textField) => {
    // We listen on blur instead of change because change is not triggered
    // when the user focuses on a field and then clicks out.
    textField.addEventListener("blur", () => handleValidation(textField));
    textField.addEventListener("input", () => {
      // This is a UX improvement to remove the error message when the user starts typing
      // in a field that has an error message. Instead of waiting for the user to click out.
      if (textField.checkValidity()) {
        textField.parentElement.querySelector(".error")?.remove();
      }
      // Ping swift with the form validity status after each input.
      webkit.messageHandlers.saveEnabled.postMessage({
        enabled: isFormValid(),
      });
    });
  });
  // Initial Swift ping with the form validity status ini.
  webkit.messageHandlers.saveEnabled.postMessage({ enabled: isFormValid() });
};

/**
 * Toggles edit mode for the address form.
 *
 * @param {Boolean} isEditable - Set to true if the form should be editable. Default is false.
 */
const toggleEditMode = (isEditable = false) => {
  const textFields = document.querySelectorAll("input,textarea");
  const selectElements = document.querySelectorAll("select");

  textFields.forEach((element) => (element.readOnly = !isEditable));
  selectElements.forEach((element) => (element.disabled = !isEditable));

  if (isEditable) {
    // Focus the first input field when entering edit mode.
    // This will show the keyboard.
    document.querySelector("input").focus();
  } else {
    // Remove focus from the input field when exiting edit mode.
    // This will hide the keyboard.
    document.activeElement.blur();
    // clear any error messages left
    document.querySelectorAll(".error").forEach((error) => error.remove());
  }
};
window.toggleEditMode = toggleEditMode;

/**
 * Reset form inside the webview.
 */
const resetForm = () => {
  document.querySelector("form").innerHTML = "";
};
window.resetForm = resetForm;
