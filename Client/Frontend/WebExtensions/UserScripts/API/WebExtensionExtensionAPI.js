/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const extension = {
  getBackgroundPage: function() {
    return window.opener;
  },
  getExtensionTabs: noimpl("getExtensionTabs"),
  getURL: function(path) {
    return WEB_EXTENSION_BASE_URL + (path.startsWith("/") ? path.substr(1) : path);
  },
  getViews: noimpl("getViews"),
  isAllowedIncognitoAccess: noimpl("isAllowedIncognitoAccess"),
  isAllowedFileSchemeAccess: noimpl("isAllowedFileSchemeAccess"),
  setUpdateUrlData: noimpl("setUpdateUrlData"),
  sendRequest: noimpl("sendRequest"),

  onRequest: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.extension.onRequest"),
  onRequestExternal: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.extension.onRequestExternal")
};

window.browser.extension = extension;
