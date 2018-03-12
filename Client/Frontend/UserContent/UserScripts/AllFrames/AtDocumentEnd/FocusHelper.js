/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
"use strict";
// The last focused element, as tracked by focus listeners
let lastFocus;
// The list of elements that can receive  focus. We cache these, and regenerate it if there is a document mutation.
let orderedElements;

//////////////////////////////////////////////////////////////////////
// This section helps the app keep track of whether the user is 
// editing text.
//
// It works by listening to focus and blur events on text areas
// and then telling swift that this tab is being edited.
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

  if (eventType.toUpperCase() === "FOCUS") {
    lastFocus = event.target;
  }
};

const initFocusTracking = () => {
  const options = {
    capture: true,
    passive: true,
  };

  const body = window.document.body;
  ["focus", "blur"].forEach((eventType) => {
    body.addEventListener(eventType, handler, options);
  });
};

//////////////////////////////////////////////////////////////////////
// This section is to help with tab navigation.
// 

const FOCUSED_ELEMENTS_STYLESHEET = `
:focus {
   outline: 1px dashed red;
}
`;
const FOCUSABLE_ELEMENTS_SELECTOR = `
a, input:not([type="hidden"]), select, button, [contenteditable]
`

const createStyleElement = () => {
  const styleElement = document.createElement("style");
  styleElement.type = "text/css";
  styleElement.appendChild(document.createTextNode(FOCUSED_ELEMENTS_STYLESHEET));

  return styleElement;
}

const findNavigatableElements = () => {
  const nodeList = document.querySelectorAll(FOCUSABLE_ELEMENTS_SELECTOR);
  const focusable = [...nodeList].filter(el => {
    if (el.hasAttribute("disabled") && el.disabled) {
      return false;
    }

    if (el.hasAttribute("contenteditable") && !el.isContentEditable) {
      return false;
    }

    if (el.hidden || el.style.display === "none") {
      return false;
    }

    return true;
  });

  const tabbable = focusable.map(el => {
    if (!el.hasAttribute("tabindex")) {
      return [0, el];
    }

    const tabindex =  +(el.getAttribute("tabindex"));
    if (Number.isNaN(tabindex)) {
      return [0, el];
    }

    return [tabindex, el];
  });


  const srcOrder = tabbable
    .filter(([tabIndex, el]) => tabIndex === 0)
    .map(([_, el]) => el);
  const tabOrder = tabbable
    .filter(([tabIndex, el]) => tabIndex > 0)
    .sort((a, b) => a[0] - b[0])
    .map(([_, el]) => el);

  return [...tabOrder, ...srcOrder];
};

const initTabKeyNavigation = () =>{
  document.documentElement.appendChild(createStyleElement());

  orderedElements = findNavigatableElements();
  const mutationObserver = new MutationObserver(function(mutations) {
    orderedElements = findNavigatableElements();
  });

  mutationObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
};

const onTabPress = (increment) => {
  let index;
  if (lastFocus) {
    index = orderedElements.findIndex((el) => lastFocus.isSameNode(el));
  } else {
    index = -1;
  }
  
  index += increment;
  const count = orderedElements.length;

  if (index < 0) {
    index = count - 1;
  } else if (index >= count) {
    index = 0;
  }

  const el = orderedElements[index];
  // lastFocus = el;
  
  if (el) {
    if (el.focus) {
      el.focus();
    }
    if (el.scrollIntoView) {
      el.scrollIntoView();
    }
    if (el.toString) {
      return `Focus now on ${index}; element=${el.toString()}`;
    }
  }

  return `Focus now on ${index}; no element`;

};

const focusHelper = {
  nextElement: () => onTabPress(+1),
  previousElement: () => onTabPress(-1),
};

Object.defineProperty(window.__firefox__, 'focusHelper', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(focusHelper)
});

initFocusTracking();
initTabKeyNavigation();