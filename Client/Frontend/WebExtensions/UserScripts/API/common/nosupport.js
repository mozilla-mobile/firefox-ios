/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

function nosupport(name) {
  return function() {
    let error = "API not supported on this platform: " + name;
    console.error(error, this);
    return Promise.reject(error);
  };
}

class UnsupportedEvent {}

UnsupportedEvent.prototype.addListener = nosupport("addListener");
UnsupportedEvent.prototype.removeListener = nosupport("removeListener");
UnsupportedEvent.prototype.hasListener = nosupport("hasListener");

module.exports = { nosupport, UnsupportedEvent };
