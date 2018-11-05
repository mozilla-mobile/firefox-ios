/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const browser = {
  browserAction: require("./WebExtensionBrowserActionAPI.js"),
  cookies: require("./WebExtensionCookiesAPI.js"),
  extension: require("./WebExtensionExtensionAPI.js"),
  i18n: require("./WebExtensionI18nAPI.js"),
  notifications: require("./WebExtensionNotificationsAPI.js"),
  runtime: require("./WebExtensionRuntimeAPI.js"),
  storage: require("./WebExtensionStorageAPI.js"),
  tabs: require("./WebExtensionTabsAPI.js"),
  webRequest: require("./WebExtensionWebRequestAPI.js")
};

module.exports = browser;
