/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const windows = {
  get: noimpl("get"),
  getCurrent: noimpl("getCurrent"),
  getLastFocused: noimpl("getLastFocused"),
  getAll: noimpl("getAll"),
  create: noimpl("create"),
  update: noimpl("update"),
  remove: noimpl("remove"),

  onCreated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.windows.onCreated"),
  onRemoved: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.windows.onRemoved"),
  onFocusChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.windows.onFocusChanged")
};

module.exports = windows;
