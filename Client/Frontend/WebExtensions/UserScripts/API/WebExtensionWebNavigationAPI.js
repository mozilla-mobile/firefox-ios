/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const webNavigation = {
  getFrame: noimpl("getFrame"),
  getAllFrames: noimpl("getAllFrames"),

  onBeforeNavigate: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onBeforeNavigate"),
  onCommitted: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onCommitted"),
  onDOMContentLoaded: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onDOMContentLoaded"),
  onCompleted: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onCompleted"),
  onErrorOccurred: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onErrorOccurred"),
  onCreatedNavigationTarget: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onCreatedNavigationTarget"),
  onReferenceFragmentUpdated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onReferenceFragmentUpdated"),
  onTabReplaced: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onTabReplaced"),
  onHistoryStateUpdated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.webNavigation.onHistoryStateUpdated")
};

module.exports = webNavigation;
