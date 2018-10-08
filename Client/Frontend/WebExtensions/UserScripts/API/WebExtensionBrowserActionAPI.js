/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const browserAction = {
  setTitle: noimpl("setTitle"),
  getTitle: noimpl("getTitle"),
  setIcon: noimpl("setIcon"),
  setPopup: noimpl("setPopup"),
  getPopup: noimpl("getPopup"),
  openPopup: noimpl("openPopup"),
  setBadgeText: noimpl("setBadgeText"),
  getBadgeText: noimpl("getBadgeText"),
  setBadgeBackgroundColor: noimpl("setBadgeBackgroundColor"),
  getBadgeBackgroundColor: noimpl("getBadgeBackgroundColor"),
  setBadgeTextColor: noimpl("setBadgeTextColor"),
  getBadgeTextColor: noimpl("getBadgeTextColor"),
  enable: noimpl("enable"),
  disable: noimpl("disable"),
  isEnabled: noimpl("isEnabled"),

  onClicked: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.browserAction.onClicked")
};

window.browser.browserAction = browserAction;
