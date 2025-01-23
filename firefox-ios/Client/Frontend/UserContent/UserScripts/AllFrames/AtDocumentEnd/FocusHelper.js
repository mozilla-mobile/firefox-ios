/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";

// Ensure this module only gets included once. This is
// required for user scripts injected into all frames.
window.__firefox__.includeOnce("FocusHelper", function() {
  const isButton = (element) => {
    if (element.nodeName !== "INPUT") {
      return false;
    }

    const type = element.type.toUpperCase();
    return (type == "BUTTON" || type == "SUBMIT" || type == "FILE");
  };

  const handler = (event) => {
    const eventType = event.type;
    const elementType = event.target.nodeName;
    // We can receive focus and blur events from `a` elements and anything with a `tabindex` attribute.
    // We should also not fire for buttons..
    if (elementType === "INPUT" || elementType === "TEXTAREA" || event.target.isContentEditable) {
      if (!isButton(event.target)) {
        webkit.messageHandlers.focusHelper.postMessage({
          eventType,
          elementType
        });
      }
    }
  };

  const options = {
    capture: true,
    passive: true,
  };

  const body = window.document.body;
  // In certain contexts, like PDF documents, the body might not exist, hence the optional chaining.
  body?.addEventListener("focus", handler, options);
  body?.addEventListener("blur", handler, options);
});
