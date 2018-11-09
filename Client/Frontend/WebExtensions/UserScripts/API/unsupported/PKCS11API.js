/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

 /**
  * NOTE: THIS IS AN UNSUPPORTED API ON iOS
  */

const { nosupport, UnsupportedEvent } = require("../common/nosupport.js");

const pkcs11 = {
  getModuleSlots: nosupport("getModuleSlots"),
  installModule: nosupport("installModule"),
  isModuleInstalled: nosupport("isModuleInstalled"),
  uninstallModule: nosupport("uninstallModule")
};

module.exports = pkcs11;
