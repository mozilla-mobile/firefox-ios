/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

import {
  enable as enableDarkMode,
  disable as disableDarkMode,
  setFetchMethod,
} from "darkreader";

// Needed in order for dark reader to handle CORS properly
// This tells dark reader to use the global window.fetch.
setFetchMethod(window.fetch);

export const setEnabled = (enabled) => {
  return enabled ? enableDarkMode() : disableDarkMode();
};