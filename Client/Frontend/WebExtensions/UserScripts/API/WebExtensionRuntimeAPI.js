/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const runtime = {
  getBackgroundPage: function() {
    if (window.opener) {
      return Promise.resolve(window.opener);
    }

    return Promise.reject();
  },
  openOptionsPage: noimpl("openOptionsPage"),
  getManifest: noimpl("getManifest"),
  getURL: function(path) {
    return WEB_EXTENSION_BASE_URL + (path.startsWith("/") ? path.substr(1) : path);
  },
  setUninstallURL: noimpl("setUninstallURL"),
  reload: noimpl("reload"),
  requestUpdateCheck: noimpl("requestUpdateCheck"),
  connect: noimpl("connect"),
  connectNative: noimpl("connectNative"),
  sendMessage: function(extensionId, message, options) {
    if (arguments.length === 1) {
      message = extensionId;
      extensionId = undefined;
    } else if (arguments.length === 2) {
      options = message;
      message = extensionId;
      extensionId = undefined;
    }

    let connection = new MessagePipeConnection();
    connection.send("runtime", "sendMessage", { extensionId, message, options });

    // TODO: Fulfill with the JSON response object sent by the handler of the message
    // in the content script, or with no arguments if the content script did not send a
    // response. If an error occurs while connecting to the specified tab or any other
    // error occurs, the promise will be rejected with an error message. If several
    // frames response to the message, the promise is resolved to one of answers.
    return Promise.resolve();
  },
  sendNativeMessage: noimpl("sendNativeMessage"),
  getPlatformInfo: noimpl("getPlatformInfo"),
  getBrowserInfo: noimpl("getBrowserInfo"),
  getPackageDirectoryEntry: noimpl("getPackageDirectoryEntry"),

  onStartup: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onStartup"),
  onInstalled: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onInstalled"),
  onSuspend: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onSuspend"),
  onSuspendCanceled: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onSuspendCanceled"),
  onUpdateAvailable: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onUpdateAvailable"),
  onBrowserUpdateAvailable: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onBrowserUpdateAvailable"),
  onConnect: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onConnect"),
  onConnectExternal: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onConnectExternal"),
  onMessage: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onMessage"),
  onMessageExternal: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onMessageExternal"),
  onRestartRequired: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.runtime.onRestartRequired")
};

module.exports = runtime;
