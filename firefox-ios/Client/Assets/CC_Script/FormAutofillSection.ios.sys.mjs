/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofillSection } from "resource://autofill/FormAutofillSection.sys.mjs";

// Since we are listening on focus events to ping swift,
// focusing inputs before filling will cause an infinite loop
FormAutofillSection.SHOULD_FOCUS_ON_AUTOFILL = false;

export { FormAutofillSection };
export * from "resource://autofill/FormAutofillSection.sys.mjs";
