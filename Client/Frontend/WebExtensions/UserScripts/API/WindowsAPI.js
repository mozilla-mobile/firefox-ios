/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const { nosupport } = require("./common/nosupport.js");

const windows = {
  get: function(windowId, getInfo) {
    let connection = new MessagePipeConnection();
    return connection.send("windows", "get", { windowId, getInfo }).then((response) => {
      return response[0];
    });
  },
  getCurrent: function(getInfo) {
    let connection = new MessagePipeConnection();
    return connection.send("windows", "getCurrent", getInfo).then((response) => {
      return response[0];
    });
  },
  getLastFocused: function(getInfo) {
    let connection = new MessagePipeConnection();
    return connection.send("windows", "getLastFocused", getInfo).then((response) => {
      return response[0];
    });
  },
  getAll: function(getInfo) {
    let connection = new MessagePipeConnection();
    return connection.send("windows", "getAll", getInfo).then((response) => {
      return response[0];
    });
  },
  create: nosupport("create"),
  update: nosupport("update"),
  remove: nosupport("remove"),

  onCreated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.windows.onCreated"),
  onRemoved: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.windows.onRemoved"),
  onFocusChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.windows.onFocusChanged")
};

module.exports = windows;
