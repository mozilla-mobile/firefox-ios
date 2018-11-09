/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * NOTE: THIS IS AN UNSUPPORTED API ON MOBILE
 * https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Differences_between_desktop_and_Android
 */

const { nosupport, UnsupportedEvent } = require("../common/nosupport.js");

const history = {
  search: nosupport("search"),
  getVisits: nosupport("getVisits"),
  addUrl: nosupport("addUrl"),
  deleteUrl: nosupport("deleteUrl"),
  deleteRange: nosupport("deleteRange"),
  deleteAll: nosupport("deleteAll"),

  onTitleChanged: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.history.onTitleChanged"),
  onVisited: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.history.onVisited"),
  onVisitRemoved: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.history.onVisitRemoved")
};

module.exports = history;
