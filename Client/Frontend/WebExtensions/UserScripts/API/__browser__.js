/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const browser = {
  browserAction: require("./BrowserActionAPI.js"),
  cookies: require("./CookiesAPI.js"),
  extension: require("./ExtensionAPI.js"),
  i18n: require("./I18nAPI.js"),
  notifications: require("./NotificationsAPI.js"),
  runtime: require("./RuntimeAPI.js"),
  storage: require("./StorageAPI.js"),
  tabs: require("./TabsAPI.js"),
  webNavigation: require("./WebNavigationAPI.js"),
  webRequest: require("./WebRequestAPI.js"),

  // Unsupported APIs on mobile
  bookmarks: require("./unsupported/BookmarksAPI.js"),
  browsingData: require("./unsupported/BrowsingDataAPI.js"),
  contextMenus: require("./unsupported/ContextMenusAPI.js"),
  devtools: require("./unsupported/DevtoolsAPI.js"),
  history: require("./unsupported/HistoryAPI.js"),
  omnibox: require("./unsupported/OmniboxAPI.js"),
  sessions: require("./unsupported/SessionsAPI.js"),
};

const chromeAPIWrapper = require("../chromeAPIWrapper.js");

const chrome = {
  browserAction: chromeAPIWrapper(browser.browserAction),
  cookies: chromeAPIWrapper(browser.cookies),
  extension: chromeAPIWrapper(browser.extension),
  i18n: chromeAPIWrapper(browser.i18n),
  notifications: chromeAPIWrapper(browser.notifications),
  runtime: chromeAPIWrapper(browser.runtime),
  storage: {
    local: chromeAPIWrapper(browser.storage.local),
    onChanged: browser.storage.onChanged
  },
  tabs: chromeAPIWrapper(browser.tabs),
  webNavigation: chromeAPIWrapper(browser.webNavigation),
  webRequest: chromeAPIWrapper(browser.webRequest),

  // Unsupported APIs on mobile
  bookmarks: chromeAPIWrapper(browser.bookmarks),
  browsingData: chromeAPIWrapper(browser.browsingData),
  contextMenus: chromeAPIWrapper(browser.contextMenus),
  devtools: {
    inspectedWindow: chromeAPIWrapper(browser.devtools.inspectedWindow),
    network: chromeAPIWrapper(browser.devtools.network),
    panels: chromeAPIWrapper(browser.devtools.panels)
  },
  history: chromeAPIWrapper(browser.history),
  omnibox: chromeAPIWrapper(browser.omnibox),
  sessions: chromeAPIWrapper(browser.sessions),
};

module.exports = { browser, chrome };
