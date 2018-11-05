/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

// Event listeners for the `webRequest` API supply additional
// arguments for filtering callbacks. To support this, we
// sub-class `NativeEvent` and wrap the supplied `callback`
// with a closure and reference the closure by the original
// `callback` function stored in a `WeakMap`.
let _callbacks = new WeakMap();

class WebRequestEvent extends NativeEvent {
  constructor(securityToken, name) {
    super(securityToken, name);
  }

  addListener(callback, filter, extraInfoSpec) {
    _callbacks.set(callback, _callbacks.get(callback) || function(details) {
      callback(details);
    });
    super.addListener(_callbacks.get(callback));
  }

  removeListener(callback) {
    super.removeListener(_callbacks.get(callback));
    _callbacks.delete(callback);
  }
}

const webRequest = {
  handlerBehaviorChanged: noimpl("handlerBehaviorChanged"),
  filterResponseData: noimpl("filterResponseData"),
  getSecurityInfo: noimpl("getSecurityInfo"),

  onBeforeRequest: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onBeforeRequest"),
  onBeforeSendHeaders: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onBeforeSendHeaders"),
  onSendHeaders: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onSendHeaders"),
  onHeadersReceived: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onHeadersReceived"),
  onAuthRequired: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onAuthRequired"),
  onResponseStarted: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onResponseStarted"),
  onBeforeRedirect: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onBeforeRedirect"),
  onCompleted: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onCompleted"),
  onErrorOccurred: new WebRequestEvent(SECURITY_TOKEN, "browser.webRequest.onErrorOccurred")
};

module.exports = webRequest;
