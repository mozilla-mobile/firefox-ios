/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * NOTE: THIS IS AN UNSUPPORTED API ON MOBILE
 * https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Differences_between_desktop_and_Android
 */

const { nosupport, UnsupportedEvent } = require("../common/nosupport.js");

const bookmarks = {
  create: nosupport("create"),
  get: nosupport("get"),
  getChildren: nosupport("getChildren"),
  getRecent: nosupport("getRecent"),
  getSubTree: nosupport("getSubTree"),
  getTree: nosupport("getTree"),
  move: nosupport("move"),
  remove: nosupport("remove"),
  removeTree: nosupport("removeTree"),
  search: nosupport("search"),
  update: nosupport("update"),

  onCreated: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.bookmarks.onCreated"),
  onRemoved: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.bookmarks.onRemoved"),
  onChanged: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.bookmarks.onChanged"),
  onMoved: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.bookmarks.onMoved"),
  onChildrenReordered: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.bookmarks.onChildrenReordered"),
  onImportBegan: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.bookmarks.onImportBegan"),
  onImportEnded: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.bookmarks.onImportEnded")
};

module.exports = bookmarks;
