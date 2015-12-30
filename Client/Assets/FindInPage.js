/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

var DEBUG_ENABLED = false;
var MATCH_HIGHLIGHT_ACTIVE = "#f19750";
var MATCH_HIGHLIGHT_INACTIVE = "#ffde49";

// window.find() sometimes gets stuck on a result, causing an infinite loop
// when we try to search (e.g., Yahoo search result pages).
// As a workaround, abort after failing too many times.
var MAX_FAILURES = 100;

var activeHighlightSpan = null;
var lastSearch;
var activeIndex = 0;
var highlightSpans = [];

function debug(str) {
  if (DEBUG_ENABLED) {
    console.log("FindInPage: " + str);
  }
}

function clearSelection() {
  if (highlightSpans.length > 0) {
    for (var span of highlightSpans) {
      var parent = span.parentNode;
      while (span.firstChild) {
        parent.insertBefore(span.firstChild, span);
      }
      parent.removeChild(span);
      parent.normalize();
    }
    highlightSpans = [];
  }
}

function highlightAllMatches(text) {
  debug("Searching: " + text)

  // Mapping of rects that have been searched. Why? window.find() is buggy, to
  // put it mildly. Sometimes it can infinitely loop in pages, even with
  // wrapping disabled (test case: search "foo" on Yahoo; find "f"). As a
  // workaround, remembering all processed rects can help us determine that
  // we've already hit this match.
  var matches = {};

  var foundRanges = [];
  clearSelection();

  // Highlight and scroll to the next match. window.getSelection() can return a Range
  // with no rects for input fields, so skip these.
  //
  // There are also weird issues on Google where window.getSelection() returns mis-sized,
  // mis-aligned rects for the absolutely positioned search suggestions box. Some of these
  // rect heights are 1px, so we can at least filter those.
  var scrollTop = document.body.scrollTop;
  var scrollLeft = document.body.scrollLeft;
  var failures = 0;

  while (true) {
    if (failures > MAX_FAILURES) {
      debug("Reached max fail count; stopping search.");
      break;
    }

    var found = window.find(text,
        /* Case sensitive   */ false,
        /* Search backwards */ false,
        /* Wrap             */ false,
        /* Whole word only  */ false,
        /* Include iframes  */ false,
        /* Show dialog      */ false);

    if (!found) {
      debug("No more results found.");
      break;
    }

    var selection = window.getSelection();

    if (selection.rangeCount == 0) {
      debug("No matches found.");
      break;
    }

    if (selection.isCollapsed) {
      failures++;
      debug("Skipping collapsed node.");
      continue;
    }

    var rects = selection.getRangeAt(0).getClientRects();

    if (!rects || rects.length == 0) {
      debug("No rects in selection.");
      continue;
    }

    var rect = rects[0];
    debug("Checking rect: " + JSON.stringify(rect));

    // Sometimes we get rects that aren't visible on the page. Skip them.
    // Test case: http://i.word.com/idictionary/hey. Search "h". First results are outside page bounds.
    var left = rect.left + scrollLeft;
    var right = rect.right + scrollLeft;
    var top = rect.top + scrollTop;
    var bottom = rect.bottom + scrollTop;
    if (right < 0 || left > document.body.scrollWidth ||
        bottom < 0 || top > document.body.scrollHeight) {
      debug("Skipping out-of-bounds rect.");
      continue;
    }

    if (rect.width == 0 || rect.height == 0) {
      debug("Skipping empty rect.");
      continue;
    }

    var rectID = getIDForRect(rect);
    if (matches[rectID]) {
      debug("Already found this rect! Aborting.");
      break;
    }
    matches[rectID] = true;

    foundRanges.push(selection.getRangeAt(0));
  }

  for (var range of foundRanges) {
    var highlight = document.createElement("span");
    highlight.style.backgroundColor = MATCH_HIGHLIGHT_INACTIVE;
    range.surroundContents(highlight);
    highlightSpans.push(highlight);
  }

  webkit.messageHandlers.findInPageHandler.postMessage({ totalResults: foundRanges.length });

  debug(foundRanges.length + " highlighted rects created!");
}

function getIDForRect(rect) {
  return rect.top + "," + rect.bottom + "," + rect.left + "," + rect.right;
}

function updateHighlightedSpan() {
  // Reset the color of the previous highlight.
  if (activeHighlightSpan) {
    activeHighlightSpan.style.backgroundColor = MATCH_HIGHLIGHT_INACTIVE;
  }

  activeHighlightSpan = highlightSpans[activeIndex];
  activeHighlightSpan.style.backgroundColor = MATCH_HIGHLIGHT_ACTIVE;

  // Find the position of the element centered on the screen, then scroll to it.
  var rect = activeHighlightSpan.getBoundingClientRect();
  var top = rect.top + scrollY - window.innerHeight / 2;
  var left = rect.left + scrollX - window.innerWidth / 2;
  left = clamp(left, 0, document.body.scrollWidth);
  top = clamp(top, 0, document.body.scrollHeight);
  window.scrollTo(left, top);
  debug("Scrolled to: " + left + ", " + top);
}

function clamp(number, min, max) {
  return Math.max(min, Math.min(number, max));
}

function updateSearch(text) {
  if (lastSearch == text) {
    // The text is the same, so we're either finding either the next or previous result.
    var totalResults = highlightSpans.length;
    activeIndex = (activeIndex + totalResults) % totalResults;
  } else {
    // The search text changed, so start again from the top.
    lastSearch = text;
    highlightAllMatches(text);
    activeIndex = 0;
  }

  var currentResult = 0;
  if (highlightSpans.length > 0) {
    updateHighlightedSpan();
    currentResult = activeIndex + 1;
  }

  // Update the UI with the current match index.
  webkit.messageHandlers.findInPageHandler.postMessage({ currentResult: currentResult });
}


if (!window.__firefox__) {
  window.__firefox__ = {};
}

window.__firefox__.find = function (text) {
  // window.find() will move on from the last result. Reset the range so that
  // we retry the last result in case it still matches the new search string.
  window.getSelection().removeAllRanges();

  updateSearch(text);
};

window.__firefox__.findNext = function (text) {
  activeIndex++;
  updateSearch(text);
};

window.__firefox__.findPrevious = function (text) {
  activeIndex--;
  updateSearch(text);
};

window.__firefox__.findDone = function () {
  clearSelection();
  lastSearch = null;
};

}) ();
