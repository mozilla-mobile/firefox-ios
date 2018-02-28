/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
(function() {
 "use strict";
 const createFormElementEventHandler = (eventType) => {
  return (event) => {
    const elementType = event.target.nodeName;
    if (elementType === "INPUT" || elementType === "TEXTAREA" || event.target.isContentEditable) {
      webkit.messageHandlers.focusHelper.postMessage({ eventType, elementType });
    }
  };
 };

 const options = {
  capture: true,
  passive: true,
 };

 const body = window.document.body;
 ["focus", "blur"].forEach((eventType) => {
  body.addEventListener(eventType, createFormElementEventHandler(eventType), options);
 });
})();
