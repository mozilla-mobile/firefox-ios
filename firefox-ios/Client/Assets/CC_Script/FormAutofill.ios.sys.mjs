/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";

FormAutofill.defineLogGetter = (scope, logPrefix) => ({
  // TODO: Bug 1828405. Explore how logging should be handled.
  // Maybe it makes more sense to do it on swift side and have JS just send messages.
  info: () => {},
  error: () => {},
  warn: () => {},
  debug: () => {},
});

export { FormAutofill };
export default FormAutofill;
