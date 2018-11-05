/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const cookies = {
  get: function(details) {
    let connection = new MessagePipeConnection();
    return connection.send("cookies", "get", details).then((response) => {
      return response[0];
    });
  },
  getAll: function(details) {
    let connection = new MessagePipeConnection();
    return connection.send("cookies", "getAll", details).then((response) => {
      return response[0];
    });
  },
  set: function(details) {
    let connection = new MessagePipeConnection();
    return connection.send("cookies", "set", details).then((response) => {
      return response[0];
    });
  },
  remove: function(details) {
    let connection = new MessagePipeConnection();
    return connection.send("cookies", "remove", details).then((response) => {
      return response[0];
    });
  },
  getAllCookieStores: noimpl("getAllCookieStores"),

  onChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.cookies.onChanged")
};

module.exports = cookies;
