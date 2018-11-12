/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const tabs = {
  captureTab: noimpl("captureTab"),
  captureVisibleTab: noimpl("captureVisibleTab"),
  connect: noimpl("connect"),
  create: function(createProperties) {
    let connection = new MessagePipeConnection();
    return connection.send("tabs", "create", createProperties).then((response) => {
      return response[0];
    });
  },
  detectLanguage: noimpl("detectLanguage"),
  discard: noimpl("discard"),
  duplicate: noimpl("duplicate"),
  executeScript: function(tabId, details) {
    let args = {};
    if (typeof tabId === "object") {
      args.details = tabId
    } else {
      args.tabId = tabId;
      args.details = details;
    }

    let connection = new MessagePipeConnection();
    return connection.send("tabs", "executeScript", args).then((response) => {
      return response[0];
    });
  },
  get: noimpl("get"),
  getAllInWindow: noimpl("getAllInWindow"),
  getCurrent: noimpl("getCurrent"),
  getSelected: noimpl("getSelected"),
  getZoom: noimpl("getZoom"),
  getZoomSettings: noimpl("getZoomSettings"),
  hide: noimpl("hide"),
  highlight: noimpl("highlight"),
  insertCSS: noimpl("insertCSS"),
  move: noimpl("move"),
  print: noimpl("print"),
  printPreview: noimpl("printPreview"),
  query: function(queryInfo) {
    let connection = new MessagePipeConnection();
    return connection.send("tabs", "query", queryInfo).then((response) => {
      return response[0];
    });
  },
  reload: noimpl("reload"),
  remove: noimpl("remove"),
  removeCSS: noimpl("removeCSS"),
  saveAsPDF: noimpl("saveAsPDF"),
  sendMessage: function(tabId, message, options) {
    let connection = new MessagePipeConnection();
    connection.send("tabs", "sendMessage", { tabId, message, options });

    // TODO: Fulfill with the JSON response object sent by the handler of the message
    // in the content script, or with no arguments if the content script did not send a
    // response. If an error occurs while connecting to the specified tab or any other
    // error occurs, the promise will be rejected with an error message. If several
    // frames response to the message, the promise is resolved to one of answers.
    return Promise.resolve();
  },
  sendRequest: noimpl("sendRequest"),
  setZoom: noimpl("setZoom"),
  setZoomSettings: noimpl("setZoomSettings"),
  show: noimpl("show"),
  toggleReaderMode: noimpl("toggleReaderMode"),
  update: noimpl("update"),

  onActivated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onActivated"),
  onActiveChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onActiveChanged"),
  onAttached: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onAttached"),
  onCreated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onCreated"),
  onDetached: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onDetached"),
  onHighlightChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onHighlightChanged"),
  onHighlighted: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onHighlighted"),
  onMoved: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onMoved"),
  onRemoved: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onRemoved"),
  onReplaced: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onReplaced"),
  onSelectionChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onSelectionChanged"),
  onUpdated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onUpdated"),
  onZoomChange: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.tabs.onZoomChange")
};

module.exports = tabs;
