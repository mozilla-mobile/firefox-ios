/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

// This array defines overrides that webpack will use when bundling the JS on iOS
// in order to load the right modules
const ModuleOverrides = {
  "AppConstants.sys.mjs": "Helpers.ios.mjs",
  "XPCOMUtils.sys.mjs": "Helpers.ios.mjs",
  "Region.sys.mjs": "Helpers.ios.mjs",
  "OSKeyStore.sys.mjs": "Helpers.ios.mjs",
  "ContentDOMReference.sys.mjs": "Helpers.ios.mjs",
  "FormAutofill.sys.mjs": "FormAutofill.ios.sys.mjs",
  "EntryFile.sys.mjs": "FormAutofillChild.ios.sys.mjs",
  "LoginHelper.sys.mjs": "LoginManager.shared.sys.mjs",
};

// We need this because not all webpack libraries used in iOS are ES Modules
// Hence we defer to CommonJS.
// eslint-disable-next-line no-undef
module.exports = { ModuleOverrides };
