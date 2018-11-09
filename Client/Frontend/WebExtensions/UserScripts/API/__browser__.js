/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const browser = {
  alarms: require("./AlarmsAPI.js"),
  browserAction: require("./BrowserActionAPI.js"),
  browserSettings: require("./BrowserSettingsAPI.js"),
  clipboard: require("./ClipboardAPI.js"),
  commands: require("./CommandsAPI.js"),
  contentScripts: require("./ContentScriptsAPI.js"),
  cookies: require("./CookiesAPI.js"),
  dns: require("./DNSAPI.js"),
  downloads: require("./DownloadsAPI.js"),
  events: require("./EventsAPI.js"),
  extension: require("./ExtensionAPI.js"),
  extensionTypes: require("./ExtensionTypesAPI.js"),
  find: require("./FindAPI.js"),
  i18n: require("./I18nAPI.js"),
  identity: require("./IdentityAPI.js"),
  idle: require("./IdleAPI.js"),
  management: require("./ManagementAPI.js"),
  notifications: require("./NotificationsAPI.js"),
  pageAction: require("./PageActionAPI.js"),
  permissions: require("./PermissionsAPI.js"),
  privacy: require("./PrivacyAPI.js"),
  proxy: require("./ProxyAPI.js"),
  runtime: require("./RuntimeAPI.js"),
  search: require("./SearchAPI.js"),
  sidebarAction: require("./SidebarActionAPI.js"),
  storage: require("./StorageAPI.js"),
  tabs: require("./TabsAPI.js"),
  theme: require("./ThemeAPI.js"),
  topSites: require("./TopSitesAPI.js"),
  types: require("./TypesAPI.js"),
  webNavigation: require("./WebNavigationAPI.js"),
  webRequest: require("./WebRequestAPI.js"),
  windows: require("./WindowsAPI.js"),

  // Unsupported APIs on mobile -- https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Differences_between_desktop_and_Android
  bookmarks: require("./unsupported/BookmarksAPI.js"),
  browsingData: require("./unsupported/BrowsingDataAPI.js"),
  devtools: require("./unsupported/DevtoolsAPI.js"),
  history: require("./unsupported/HistoryAPI.js"),
  menus: require("./unsupported/MenusAPI.js"),
  omnibox: require("./unsupported/OmniboxAPI.js"),
  sessions: require("./unsupported/SessionsAPI.js"),

  // Unsupported APIs on iOS
  contextualIdentities: require("./unsupported/ContextualIdentitiesAPI.js"),
  pkcs11: require("./unsupported/PKCS11API.js")
};

const chromeAPIWrapper = require("../chromeAPIWrapper.js");

const chrome = {
  alarms: chromeAPIWrapper(browser.alarms),
  browserAction: chromeAPIWrapper(browser.browserAction),
  browserSettings: chromeAPIWrapper(browser.browserSettings),
  clipboard: chromeAPIWrapper(browser.clipboard),
  commands: chromeAPIWrapper(browser.commands),
  contentScripts: chromeAPIWrapper(browser.contentScripts),
  cookies: chromeAPIWrapper(browser.cookies),
  dns: chromeAPIWrapper(browser.dns),
  downloads: chromeAPIWrapper(browser.downloads),
  events: chromeAPIWrapper(browser.events),
  extension: chromeAPIWrapper(browser.extension),
  extensionTypes: chromeAPIWrapper(browser.extensionTypes),
  find: chromeAPIWrapper(browser.find),
  i18n: chromeAPIWrapper(browser.i18n),
  identity: chromeAPIWrapper(browser.identity),
  idle: chromeAPIWrapper(browser.idle),
  management: chromeAPIWrapper(browser.management),
  notifications: chromeAPIWrapper(browser.notifications),
  pageAction: chromeAPIWrapper(browser.pageAction),
  permissions: chromeAPIWrapper(browser.permissions),
  privacy: chromeAPIWrapper(browser.privacy),
  proxy: chromeAPIWrapper(browser.proxy),
  runtime: chromeAPIWrapper(browser.runtime),
  search: chromeAPIWrapper(browser.search),
  sidebarAction: chromeAPIWrapper(browser.sidebarAction),
  storage: {
    local: chromeAPIWrapper(browser.storage.local),
    onChanged: browser.storage.onChanged
  },
  tabs: chromeAPIWrapper(browser.tabs),
  theme: chromeAPIWrapper(browser.theme),
  topSites: chromeAPIWrapper(browser.topSites),
  types: chromeAPIWrapper(browser.types),
  webNavigation: chromeAPIWrapper(browser.webNavigation),
  webRequest: chromeAPIWrapper(browser.webRequest),
  windows: chromeAPIWrapper(browser.windows),

  // Unsupported APIs on mobile -- https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Differences_between_desktop_and_Android
  bookmarks: chromeAPIWrapper(browser.bookmarks),
  browsingData: chromeAPIWrapper(browser.browsingData),
  devtools: {
    inspectedWindow: chromeAPIWrapper(browser.devtools.inspectedWindow),
    network: chromeAPIWrapper(browser.devtools.network),
    panels: chromeAPIWrapper(browser.devtools.panels)
  },
  history: chromeAPIWrapper(browser.history),
  menus: chromeAPIWrapper(browser.menus),
  omnibox: chromeAPIWrapper(browser.omnibox),
  sessions: chromeAPIWrapper(browser.sessions),

  // Unsupported APIs on iOS
  contextualIdentities: chromeAPIWrapper(browser.contextualIdentities),
  pkcs11: chromeAPIWrapper(browser.pkcs11)
};

module.exports = { browser, chrome };
