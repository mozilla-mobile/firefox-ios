/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

const MAXIMUM_HIGHLIGHT_COUNT = 500;
const SCROLL_OFFSET_Y = 40;

const HIGHLIGHT_CLASS_NAME = "__firefox__find-highlight";
const HIGHLIGHT_CLASS_NAME_ACTIVE = "__firefox__find-highlight-active";

const HIGHLIGHT_COLOR = "#ffde49";
const HIGHLIGHT_COLOR_ACTIVE = "#f19750";

const HIGHLIGHT_CSS =
`.${HIGHLIGHT_CLASS_NAME} {
  color: #000;
  background-color: ${HIGHLIGHT_COLOR};
  border-radius: 1px;
  box-shadow: 0 0 0 2px ${HIGHLIGHT_COLOR};
  transition: all 100ms ease;
}
.${HIGHLIGHT_CLASS_NAME}.${HIGHLIGHT_CLASS_NAME_ACTIVE} {
  background-color: ${HIGHLIGHT_COLOR_ACTIVE};
  box-shadow: 0 0 0 3px ${HIGHLIGHT_COLOR_ACTIVE},0 1px 3px 3px rgba(0,0,0,.75);
}`;

var lastEscapedQuery = "";
var lastFindOperation = null;
var lastReplacements = null;
var lastHighlights = null;
var activeHighlightIndex = -1;

var highlightSpan = document.createElement("span");
highlightSpan.className = HIGHLIGHT_CLASS_NAME;

var styleElement = document.createElement("style");
styleElement.innerHTML = HIGHLIGHT_CSS;

function find(query) {
  let escapedQuery = query.trim().replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1");
  if (escapedQuery !== lastEscapedQuery) {
    if (lastFindOperation) {
      lastFindOperation.cancel();
    }

    clear();

    lastEscapedQuery = escapedQuery;
  }

  if (!escapedQuery) {
    return;
  }

  let queryRegExp = new RegExp("(" + escapedQuery + ")", "gi");

  lastFindOperation = getMatchingNodeReplacements(queryRegExp, function(replacements, highlights) {
    let replacement;
    for (let i = 0, length = replacements.length; i < length; i++) {
      replacement = replacements[i];

      replacement.originalNode.replaceWith(replacement.replacementFragment);
    }

    lastFindOperation = null;
    lastReplacements = replacements;
    lastHighlights = highlights;
    activeHighlightIndex = -1;

    let totalResults = highlights.length;
    webkit.messageHandlers.findInPageHandler.postMessage({ totalResults: totalResults });

    findNext();
  });
}

function findNext() {
  if (lastHighlights) {
    activeHighlightIndex = (activeHighlightIndex + lastHighlights.length + 1) % lastHighlights.length;
    updateActiveHighlight();
  }
}

function findPrevious() {
  if (lastHighlights) {
    activeHighlightIndex = (activeHighlightIndex + lastHighlights.length - 1) % lastHighlights.length;
    updateActiveHighlight();
  }
}

function findDone() {
  styleElement.remove();
  clear();

  lastEscapedQuery = "";
}

function clear() {
  if (!lastHighlights) {
    return;
  }

  let replacements = lastReplacements;
  let highlights = lastHighlights;

  let highlight;
  for (let i = 0, length = highlights.length; i < length; i++) {
    highlight = highlights[i];

    removeHighlight(highlight);
  }

  lastReplacements = null;
  lastHighlights = null;
  activeHighlightIndex = -1;

  webkit.messageHandlers.findInPageHandler.postMessage({ currentResult: 0, totalResults: 0 });
}

function updateActiveHighlight() {
  if (!styleElement.parentNode) {
    document.body.appendChild(styleElement);
  }

  let lastActiveHighlight = document.querySelector("." + HIGHLIGHT_CLASS_NAME_ACTIVE);
  if (lastActiveHighlight) {
    lastActiveHighlight.className = HIGHLIGHT_CLASS_NAME;
  }

  if (!lastHighlights) {
    return;
  }

  let activeHighlight = lastHighlights[activeHighlightIndex];
  if (activeHighlight) {
    activeHighlight.className = HIGHLIGHT_CLASS_NAME + " " + HIGHLIGHT_CLASS_NAME_ACTIVE;
    scrollToElement(activeHighlight);

    webkit.messageHandlers.findInPageHandler.postMessage({ currentResult: activeHighlightIndex + 1 });
  }
}

function removeHighlight(highlight) {
  let parent = highlight.parentNode;
  if (parent) {
    while (highlight.firstChild) {
      parent.insertBefore(highlight.firstChild, highlight);
    }

    highlight.remove();
    parent.normalize();
  }
}

function asyncTextNodeWalker(iterator, callback) {
  let operation = new Operation();
  let walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);

  chunkedLoop(function() { return walker.nextNode(); }, function(node) {
    if (operation.cancelled) {
      return false;
    }

    iterator(node);
  }, 100).then(function() {
    operation.complete();
  });

  return operation;
}

function getMatchingNodeReplacements(regExp, callback) {
  let replacements = [];
  let highlights = [];
  let isMaximumHighlightCount = false;

  let operation = asyncTextNodeWalker(function(originalNode) {
    let originalTextContent = originalNode.textContent;
    let lastIndex = 0;
    let replacementFragment = document.createDocumentFragment();
    let hasReplacement = false;
    let match;

    while ((match = regExp.exec(originalTextContent))) {
      let matchTextContent = match[0];

      // Add any text before this match.
      if (match.index > 0) {
        let leadingSubstring = originalTextContent.substring(lastIndex, match.index);
        replacementFragment.appendChild(document.createTextNode(leadingSubstring));
      }

      // Add element for this match.
      let element = highlightSpan.cloneNode(false);
      element.textContent = matchTextContent;
      replacementFragment.appendChild(element);
      highlights.push(element);

      lastIndex = regExp.lastIndex;
      hasReplacement = true;

      if (highlights.length > MAXIMUM_HIGHLIGHT_COUNT) {
        isMaximumHighlightCount = true;
        break;
      }
    }

    if (hasReplacement) {
      // Add any text after the matches.
      if (lastIndex < originalTextContent.length) {
        let trailingSubstring = originalTextContent.substring(lastIndex, originalTextContent.length);
        replacementFragment.appendChild(document.createTextNode(trailingSubstring));
      }

      replacements.push({
        originalNode: originalNode,
        replacementFragment: replacementFragment
      });
    }

    if (isMaximumHighlightCount) {
      operation.cancel();
      callback(replacements, highlights);
    }
  });

  // Callback for if/when the text node loop completes (should
  // happen unless the maximum highlight count is reached).
  operation.oncompleted = function() {
    callback(replacements, highlights);
  };

  return operation;
}

function chunkedLoop(condition, iterator, chunkSize) {
  return new Promise(function(resolve, reject) {
    setTimeout(doChunk);

    function doChunk() {
      let argument;
      for (let i = 0; i < chunkSize; i++) {
        argument = condition();
        if (!argument || iterator(argument) === false) {
          resolve();
          return;
        }
      }

      setTimeout(doChunk);
    }
  });
}

function scrollToElement(element) {
  let rect = element.getBoundingClientRect();
  let x = clamp(rect.left + window.scrollX - window.innerWidth / 2, 0, document.body.scrollWidth);
  let y = clamp(SCROLL_OFFSET_Y + rect.top + window.scrollY - window.innerHeight / 2, 0, document.body.scrollHeight);
  window.scrollTo(x, y);
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(value, max));
}

function Operation() {
  this.cancelled = false;
  this.completed = false;
}

Operation.prototype.constructor = Operation;

Operation.prototype.cancel = function() {
  this.cancelled = true;

  if (typeof this.oncancelled === "function") {
    this.oncancelled();
  }
};

Operation.prototype.complete = function() {
  this.completed = true;

  if (typeof this.oncompleted === "function") {
    this.oncompleted();
  }
};

Object.defineProperty(window.__firefox__, "find", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: find
});

Object.defineProperty(window.__firefox__, "findNext", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: findNext
});

Object.defineProperty(window.__firefox__, "findPrevious", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: findPrevious
});

Object.defineProperty(window.__firefox__, "findDone", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: findDone
});
