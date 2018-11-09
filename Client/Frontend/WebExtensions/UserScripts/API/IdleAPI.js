/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const idle = {
  queryState: noimpl("queryState"),
  setDetectionInterval: noimpl("setDetectionInterval"),

  onStateChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.idle.onStateChanged")
};

module.exports = idle;
