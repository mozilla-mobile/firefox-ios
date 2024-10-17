/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import "resource://gre/modules/shared/Helpers.ios.mjs";
import {
  createFormLayoutFromRecord,
  getCurrentFormData,
} from "resource://gre/modules/shared/addressFormLayout.mjs";

// Expose getCurrentFormData to the window object.
window.getCurrentFormData = getCurrentFormData;
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

  if (lines <= 1) {
    textarea.style.height = `${initialHeight}px`;
  } else {
    textarea.style.height = `${textarea.scrollHeight}px`;
  }
};

/**
 * Renders an address form into the webview from a record.
 *
 * @param {object} record - Address record, includes at least country code defaulted to FormAutofill.DEFAULT_REGION.
 * @param {object} l10nStrings - Localization strings map.
 */
const init = (record, l10nStrings, isDarkTheme = false) => {
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
    const rowHeight = document.querySelector("input").clientHeight;
    autoResizeTextarea(textarea, rowHeight);
    textarea.addEventListener("input", () => autoResizeTextarea(textarea));
  });

  // By default on init, the form is not editable.
  toggleEditMode(false);
};
window.init = init;

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
