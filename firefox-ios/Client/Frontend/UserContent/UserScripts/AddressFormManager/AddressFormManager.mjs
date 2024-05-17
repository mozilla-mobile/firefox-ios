/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import "resource://gre/modules/shared/Helpers.ios.mjs";
import { createFormLayoutFromRecord } from "resource://gre/modules/shared/addressFormLayout.mjs";

/**
 * Renders an address form into the webview from a record.
 *
 * @param {object} record - Address record, includes at least country code defaulted to FormAutofill.DEFAULT_REGION.
 * @param {object} l10nStrings - Localization strings map.
 */
const init = (record, l10nStrings) => {
  createFormLayoutFromRecord(
    document.querySelector("form"),
    record,
    l10nStrings
  );

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

  textFields[0].focus();
};
window.toggleEditMode = toggleEditMode;
