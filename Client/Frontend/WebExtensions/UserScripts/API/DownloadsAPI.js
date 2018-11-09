/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const downloads = {
  download: noimpl("download"),
  search: noimpl("search"),
  pause: noimpl("pause"),
  resume: noimpl("resume"),
  cancel: noimpl("cancel"),
  getFileIcon: noimpl("getFileIcon"),
  open: noimpl("open"),
  show: noimpl("show"),
  showDefaultFolder: noimpl("showDefaultFolder"),
  erase: noimpl("erase"),
  removeFile: noimpl("removeFile"),
  acceptDanger: noimpl("acceptDanger"),
  drag: noimpl("drag"),
  setShelfEnabled: noimpl("setShelfEnabled"),

  onCreated: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.downloads.onCreated"),
  onErased: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.downloads.onErased"),
  onChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.downloads.onChanged")
};

module.exports = downloads;
