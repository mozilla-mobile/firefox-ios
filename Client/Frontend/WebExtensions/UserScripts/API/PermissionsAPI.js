/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const permissions = {
  contains: noimpl("contains"),
  getAll: noimpl("getAll"),
  remove: noimpl("remove"),
  request: noimpl("request"),

  onAdded: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.permissions.onAdded"),
  onRemoved: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.permissions.onRemoved")
};

module.exports = permissions;
