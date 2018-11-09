/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * NOTE: THIS IS AN UNSUPPORTED API ON MOBILE
 * https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Differences_between_desktop_and_Android
 */

const { nosupport, UnsupportedEvent } = require("../common/nosupport.js");

const contextMenus = {
  create: nosupport("create"),
  getTargetElement: nosupport("getTargetElement"),
  refresh: nosupport("refresh"),
  remove: nosupport("remove"),
  removeAll: nosupport("removeAll"),
  update: nosupport("update"),

  onClicked: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.contextMenus.onClicked"),
  onHidden: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.contextMenus.onHidden"),
  onShown: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.contextMenus.onShown")
};

module.exports = contextMenus;
