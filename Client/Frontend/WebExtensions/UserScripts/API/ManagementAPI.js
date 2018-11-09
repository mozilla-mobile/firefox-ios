/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const management = {
  getAll: noimpl("getAll"),
  get: noimpl("get"),
  getSelf: noimpl("getSelf"),
  install: noimpl("install"),
  uninstall: noimpl("uninstall"),
  uninstallSelf: noimpl("uninstallSelf"),
  getPermissionWarningsById: noimpl("getPermissionWarningsById"),
  getPermissionWarningsByManifest: noimpl("getPermissionWarningsByManifest"),
  setEnabled: noimpl("setEnabled"),

  onInstalled: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.management.onInstalled"),
  onUninstalled: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.management.onUninstalled"),
  onEnabled: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.management.onEnabled"),
  onDisabled: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.management.onDisabled")
};

module.exports = management;
