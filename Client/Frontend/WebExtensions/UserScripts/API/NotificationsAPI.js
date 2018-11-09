/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");
const uuid = require("./common/uuid.js");

const notifications = {
  clear: noimpl("clear"),
  create: function(id, options) {
    if (typeof id !== "string") {
      options = id;
      id = undefined;
    }

    if (!id) {
      id = uuid();
    }

    // TODO: Fulfill with the proper response once the notification is
    // actually displayed to the user.
    let connection = new MessagePipeConnection();
    connection.send("notifications", "create", { id, options });

    return Promise.resolve();
  },
  getAll: noimpl("getAll"),
  update: noimpl("update"),

  onButtonClicked: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.notifications.onButtonClicked"),
  onClicked: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.notifications.onClicked"),
  onClosed: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.notifications.onClosed"),
  onShown: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.notifications.onShown")
};

module.exports = notifications;
