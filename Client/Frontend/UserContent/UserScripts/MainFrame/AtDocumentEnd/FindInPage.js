/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

const MAXIMUM_HIGHLIGHT_COUNT = 500;
const SCROLL_OFFSET_Y = 40;
const SCROLL_DURATION = 100;

const HIGHLIGHT_CLASS_NAME = "__firefox__find-highlight";
const HIGHLIGHT_CLASS_NAME_ACTIVE = "__firefox__find-highlight-active";

const HIGHLIGHT_COLOR = "#ffde49";
const HIGHLIGHT_COLOR_ACTIVE = "#f19750";

// IMPORTANT!!!: If this CSS is ever changed, the sha256-base64
// hash in Client/Frontend/Reader/ReaderModeHandlers.swift will
// also need updated. The value of `ReaderModeStyleHash` in that
// file represents the sha256-base64 hash of the `HIGHLIGHT_CSS`.
const HIGHLIGHT_CSS =
`.${HIGHLIGHT_CLASS_NAME} {
  color: #000;
  background-color: ${HIGHLIGHT_COLOR};
  border-radius: 1px;
  box-shadow: 0 0 0 2px ${HIGHLIGHT_COLOR};
  transition: all ${SCROLL_DURATION}ms ease ${SCROLL_DURATION}ms;
}
.${HIGHLIGHT_CLASS_NAME}.${HIGHLIGHT_CLASS_NAME_ACTIVE} {
  background-color: ${HIGHLIGHT_COLOR_ACTIVE};
  box-shadow: 0 0 0 4px ${HIGHLIGHT_COLOR_ACTIVE},0 1px 3px 3px rgba(0,0,0,.75);
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
  let trimmedQuery = query.trim();

  // If the trimmed query is empty, use it instead of the escaped
  // query to prevent searching for nothing but whitepsace.
  let escapedQuery = !trimmedQuery ? trimmedQuery : query.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1");
  if (escapedQuery === lastEscapedQuery) {
    return;
  }

  if (lastFindOperation) {
    lastFindOperation.cancel();
  }

  clear();

  lastEscapedQuery = escapedQuery;

  if (!escapedQuery) {
    webkit.messageHandlers.findInPageHandler.postMessage({ currentResult: 0, totalResults: 0 });
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
    scrollToElement(activeHighlight, SCROLL_DURATION);

    webkit.messageHandlers.findInPageHandler.postMessage({ currentResult: activeHighlightIndex + 1 });
  } else {
    webkit.messageHandlers.findInPageHandler.postMessage({ currentResult: 0 });
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

function asyncTextNodeWalker(iterator) {
  let operation = new Operation();
  let walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);

  let timeout = setTimeout(function() {
    chunkedLoop(function() { return walker.nextNode(); }, function(node) {
      if (operation.cancelled) {
        return false;
      }

      iterator(node);
      return true;
    }, 100).then(function() {
      operation.complete();
    });
  }, 50);

  operation.oncancelled = function() {
    clearTimeout(timeout);
  };

  return operation;
}

function getMatchingNodeReplacements(regExp, callback) {
  let replacements = [];
  let highlights = [];
  let isMaximumHighlightCount = false;

  let operation = asyncTextNodeWalker(function(originalNode) {
    if (!isTextNodeVisible(originalNode) || originalNode.parentElement.nodeName === "IFRAME") {
      return;
    }

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
    setTimeout(doChunk, 0);

    function doChunk() {
      let argument;
      for (let i = 0; i < chunkSize; i++) {
        argument = condition();
        if (!argument || iterator(argument) === false) {
          resolve();
          return;
        }
      }

      setTimeout(doChunk, 0);
    }
  });
}

function scrollToElement(element, duration) {
  let rect = element.getBoundingClientRect();

  let targetX = clamp(rect.left + window.scrollX - window.innerWidth / 2, 0, document.body.scrollWidth);
  let targetY = clamp(SCROLL_OFFSET_Y + rect.top + window.scrollY - window.innerHeight / 2, 0, document.body.scrollHeight);

  let startX = window.scrollX;
  let startY = window.scrollY;

  let deltaX = targetX - startX;
  let deltaY = targetY - startY;

  let startTimestamp;

  function step(timestamp) {
    if (!startTimestamp) {
      startTimestamp = timestamp;
    }

    let time = timestamp - startTimestamp;
    let percent = Math.min(time / duration, 1);

    let x = startX + deltaX * percent;
    let y = startY + deltaY * percent;

    window.scrollTo(x, y);

    if (time < duration) {
      requestAnimationFrame(step);
    }
  }

  requestAnimationFrame(step);
}

function isTextNodeVisible(textNode) {
  let element = textNode.parentElement;
  if (!element) {
    return false;
  }
  return !!(element.offsetWidth || element.offsetHeight || element.getClientRects().length);
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
    if (!this.cancelled) {
      this.oncompleted();
    }
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
