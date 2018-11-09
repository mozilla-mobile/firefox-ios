/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

 /**
  * NOTE: THIS IS AN UNSUPPORTED API ON MOBILE
  * https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Differences_between_desktop_and_Android
  */

const { nosupport, UnsupportedEvent } = require("../common/nosupport.js");

const browsingData = {
  remove: nosupport("remove"),
  removeCache: nosupport("removeCache"),
  removeCookies: nosupport("removeCookies"),
  removeDownloads: nosupport("removeDownloads"),
  removeFormData: nosupport("removeFormData"),
  removeHistory: nosupport("removeHistory"),
  removeLocalStorage: nosupport("removeLocalStorage"),
  removePasswords: nosupport("removePasswords"),
  removePluginData: nosupport("removePluginData"),
  settings: nosupport("settings")
};

module.exports = browsingData;
