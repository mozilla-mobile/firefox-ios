/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const sidebarAction = {
  setPanel: noimpl("setPanel"),
  getPanel: noimpl("getPanel"),
  setTitle: noimpl("setTitle"),
  getTitle: noimpl("getTitle"),
  setIcon: noimpl("setIcon"),
  open: noimpl("open"),
  close: noimpl("close"),
  isOpen: noimpl("isOpen")
};

module.exports = sidebarAction;
