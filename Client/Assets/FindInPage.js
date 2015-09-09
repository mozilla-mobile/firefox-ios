/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

var DEBUG_ENABLED = true;
var ACTIVE_COLOR = "#f88017";
var INACTIVE_COLOR = "#fcd0a7";

var highlightDiv = null;
var activeHighlightRect = null;
var lastSearch;
var activeIndex = 0;

window.debugResults = [];

function clearSelection() {
  if (highlightDiv) {
    document.documentElement.removeChild(highlightDiv);
    highlightDiv = null;
  }
}

function debug(str) {
  if (DEBUG_ENABLED) {
    console.log("FindInPage: " + str);
  }
}

function findAllRects(text) {
  debug("Searching: " + text)

  var foundRects = [];
  clearSelection();
  window.debugResults = [];

  // Highlight and scroll to the next match. window.getSelection() can return a Range
  // with no rects for input fields, so skip these.
  //
  // There are also weird issues on Google where window.getSelection() returns mis-sized,
  // mis-aligned rects for the absolutely positioned search suggestions box. Some of these
  // rect heights are 1px, so we can at least filter those.
  var scrollTop = document.body.scrollTop;
  var scrollLeft = document.body.scrollLeft;

  while (true) {
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

    window.debugResults.push(selection.anchorNode);
    foundRects.push(rect);
  }

  if (foundRects.length == 0) {
    debug("No highlight rects created!");
    return;
  }

  createHighlightOverlay(foundRects);
  webkit.messageHandlers.findInPageHandler.postMessage({ totalResults: foundRects.length });

  debug(foundRects.length + " highlighted rects created!");
}

function updateHighlightedRect() {
  // Reset the color of the previous highlight.
  if (activeHighlightRect) {
    activeHighlightRect.style.backgroundColor = INACTIVE_COLOR;
  }

  activeHighlightRect = highlightDiv.children[activeIndex];
  activeHighlightRect.style.backgroundColor = ACTIVE_COLOR;

  // Find the position of the element centered on the screen, then scroll to it.
  var top = activeHighlightRect.offsetTop - window.innerHeight / 2;
  var left = activeHighlightRect.offsetLeft - window.innerWidth / 2;
  left = clamp(left, 0, document.body.scrollWidth);
  top = clamp(top, 0, document.body.scrollHeight);
  window.scrollTo(left, top);
  debug("Scrolled to: " + left + ", " + top);
}

function clamp(number, min, max) {
  return Math.max(min, Math.min(number, max));
}

function createHighlightOverlay(rects) {
  // Create a parent element to hold each highlight rect.
  // This allows us to set the opacity for the entire highlight
  // without worrying about overlapping opacities for each child.
  highlightDiv = document.createElement("div");
  highlightDiv.style.pointerEvents = "none";
  highlightDiv.style.top = "0px";
  highlightDiv.style.left = "0px";
  highlightDiv.style.position = "absolute";
  highlightDiv.style.opacity = 0.3;
  highlightDiv.style.zIndex = 99999;
  document.documentElement.appendChild(highlightDiv);

  for (var i = 0; i != rects.length; i++) {
    var rect = rects[i];
    var rectDiv = document.createElement("div");
    var scrollTop = document.body.scrollTop;
    var scrollLeft = document.body.scrollLeft;
    var top = rect.top + scrollTop;
    var left = rect.left + scrollLeft;

    rectDiv.style.top = top + "px";
    rectDiv.style.left = left + "px";
    rectDiv.style.width = rect.width + "px";
    rectDiv.style.height = rect.height + "px";
    rectDiv.style.position = "absolute";
    rectDiv.style.backgroundColor = INACTIVE_COLOR;
    rectDiv.style.pointerEvents = "none";

    highlightDiv.appendChild(rectDiv);
  }
}

function updateSearch(text) {
  if (lastSearch == text) {
    // The text is the same, so we're either finding either the next or previous result.
    var totalResults = highlightDiv.children.length;
    activeIndex = (activeIndex + totalResults) % totalResults;
  } else {
    // The search text changed, so start again from the top.
    lastSearch = text;
    findAllRects(text);
    activeIndex = 0;
  }

  if (highlightDiv) {
    updateHighlightedRect();
  }

  webkit.messageHandlers.findInPageHandler.postMessage({ currentResult: activeIndex + 1 });
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
};

}) ();
