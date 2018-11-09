/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * NOTE: THIS IS AN UNSUPPORTED API ON iOS
 */

const { nosupport, UnsupportedEvent } = require("../common/nosupport.js");

const contextualIdentities = {
  create: nosupport("create"),
  get: nosupport("get"),
  query: nosupport("query"),
  update: nosupport("update"),
  remove: nosupport("remove"),

  onCreated: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.contextualIdentities.onCreated"),
  onRemoved: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.contextualIdentities.onRemoved"),
  onUpdated: new UnsupportedEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.contextualIdentities.onUpdated")
};

module.exports = contextualIdentities;
