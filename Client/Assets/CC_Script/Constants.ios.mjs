/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const IOS_DEFAULT_PREFERENCES = {
  "extensions.formautofill.creditCards.heuristics.mode": 1,
  "extensions.formautofill.creditCards.heuristics.fathom.confidenceThreshold": 0.5,
  "extensions.formautofill.creditCards.heuristics.fathom.highConfidenceThreshold": 0.95,
  "extensions.formautofill.creditCards.heuristics.fathom.testConfidence": 0,
  "extensions.formautofill.creditCards.heuristics.fathom.types":
    "cc-number,cc-name",
  "extensions.formautofill.loglevel": "Warn",
  "extensions.formautofill.addresses.supported": "off",
  "extensions.formautofill.creditCards.supported": "detect",
  "browser.search.region": "US",
  "extensions.formautofill.creditCards.supportedCountries": "US,CA,GB,FR,DE",
  "extensions.formautofill.addresses.enabled": false,
  "extensions.formautofill.addresses.capture.enabled": false,
  "extensions.formautofill.addresses.capture.v2.enabled": false,
  "extensions.formautofill.addresses.supportedCountries": "",
  "extensions.formautofill.creditCards.enabled": true,
  "extensions.formautofill.reauth.enabled": true,
  "extensions.formautofill.creditCards.hideui": false,
  "extensions.formautofill.supportRTL": false,
  "extensions.formautofill.creditCards.ignoreAutocompleteOff": true,
  "extensions.formautofill.addresses.ignoreAutocompleteOff": true,
  "extensions.formautofill.heuristics.enabled": true,
  "extensions.formautofill.section.enabled": true,
  // WebKit doesn't support the checkVisibility API, setting the threshold value to 0 to ensure
  // `IsFieldVisible` function doesn't use it
  "extensions.formautofill.heuristics.visibilityCheckThreshold": 0,
  "extensions.formautofill.heuristics.interactivityCheckMode": "focusability",
  "extensions.formautofill.focusOnAutofill": false,
};

// Used Mimic the behavior of .getAutocompleteInfo()
// List from: https://searchfox.org/mozilla-central/source/dom/base/AutocompleteFieldList.h#89-149
// Also found here: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
const VALID_AUTOCOMPLETE_FIELDS = [
  "off",
  "on",
  "name",
  "honorific-prefix",
  "given-name",
  "additional-name",
  "family-name",
  "honorific-suffix",
  "nickname",
  "email",
  "username",
  "new-password",
  "current-password",
  "one-time-code",
  "organization-title",
  "organization",
  "street-address",
  "address-line1",
  "address-line2",
  "address-line3",
  "address-level4",
  "address-level3",
  "address-level2",
  "address-level1",
  "country",
  "country-name",
  "postal-code",
  "cc-name",
  "cc-given-name",
  "cc-additional-name",
  "cc-family-name",
  "cc-number",
  "cc-exp",
  "cc-exp-month",
  "cc-exp-year",
  "cc-csc",
  "cc-type",
  "transaction-currency",
  "transaction-amount",
  "language",
  "bday",
  "bday-day",
  "bday-month",
  "bday-year",
  "sex",
  "tel",
  "tel-country-code",
  "tel-national",
  "tel-area-code",
  "tel-local",
  "tel-extension",
  "impp",
  "url",
  "photo",
];

export const IOSAppConstants = Object.freeze({
  platform: "ios",
  prefs: IOS_DEFAULT_PREFERENCES,
  validAutocompleteFields: VALID_AUTOCOMPLETE_FIELDS,
});

export default IOSAppConstants;
