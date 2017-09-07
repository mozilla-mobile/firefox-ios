/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {

"use strict";

var MAX_RADIUS = 9;

var longPressTimeout = null;
var touchDownX = 0;
var touchDownY = 0;
var highlightDiv = null;
var touchHandled = false;
var element = null;

function cancel() {
  if (longPressTimeout) {
    clearTimeout(longPressTimeout);
    longPressTimeout = null;

    if (highlightDiv) {
      document.body.removeChild(highlightDiv);
      highlightDiv = null;
    }
  }
}

function createHighlightOverlay(element) {
  // Create a parent element to hold each highlight rect.
  // This allows us to set the opacity for the entire highlight
  // without worrying about overlapping opacities for each child.
  highlightDiv = document.createElement("div");
  highlightDiv.style.pointerEvents = "none";
  highlightDiv.style.top = "0px";
  highlightDiv.style.left = "0px";
  highlightDiv.style.position = "absolute";
  highlightDiv.style.opacity = 0.1;
  highlightDiv.style.zIndex = 99999;
  document.body.appendChild(highlightDiv);

  var rects = element.getClientRects();
  for (var i = 0; i != rects.length; i++) {
    var rect = rects[i];
    var rectDiv = document.createElement("div");
    var scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
    var scrollLeft = document.documentElement.scrollLeft || document.body.scrollLeft;
    var top = rect.top + scrollTop - 2.5;
    var left = rect.left + scrollLeft - 2.5;

    // These styles are as close as possible to the default highlight style used
    // by the web view.
    rectDiv.style.top = top + "px";
    rectDiv.style.left = left + "px";
    rectDiv.style.width = rect.width + "px";
    rectDiv.style.height = rect.height + "px";
    rectDiv.style.position = "absolute";
    rectDiv.style.backgroundColor = "#000";
    rectDiv.style.borderRadius = "2px";
    rectDiv.style.padding = "2.5px";
    rectDiv.style.pointerEvents = "none";

    highlightDiv.appendChild(rectDiv);
  }
}

function handleTouchMove(event) {
  if (longPressTimeout) {
       var { screenX, screenY } = event.touches[0];
        // Cancel the context menu if finger has moved beyond the maximum allowed distance.
       if (Math.abs(touchDownX - screenX) > MAX_RADIUS || Math.abs(touchDownY - screenY) > MAX_RADIUS) {
         cancel();
      }
   }
}

function handleTouchEnd(event) {
  cancel();

  window.removeEventListener("touchend", handleTouchEnd);
  window.removeEventListener("touchmove", handleTouchMove);

  setTimeout(function() {
    if (element) {
      element.removeEventListener("click", handleClick, true);
    }
  });

  // If we're showing the context menu, prevent the page from handling the click event.
  if (touchHandled) {
    touchHandled = false;
    event.preventDefault();
    event.stopPropagation();
  }
}

function handleClick(event) {
  this.removeEventListener("click", handleClick, true);
  event.preventDefault();
  event.stopPropagation();
}

window.addEventListener("touchstart", function(event) {
  setTimeout(function() {
    // Don't show the context menu if another event listener has already
    // prevented the default behavior or if more than one touch is present.
    if (event.defaultPrevented || event.touches.length !== 1) {
      cancel();
      return;
    }

    var data = {};

    // Don't show the context menu if this element is has the
    // -webkit-touch-callout: none CSS property applied.
    var style = getComputedStyle(event.target);
    if (style.webkitTouchCallout === "none") {
      cancel();
      return;
    }

    element = event.target.closest("a");
    if (element) {
      data.link = element.href;

      // The web view still shows the tap highlight after clicking an element,
      // so add a delay before showing the long press highlight to avoid
      // the highlight flashing twice.
      setTimeout(function() {
        if (longPressTimeout) {
          createHighlightOverlay(element);
        }
      }, 100);

      // Listen for touchend or move events to cancel the context menu timeout.
      window.addEventListener("touchend", handleTouchEnd);
      window.addEventListener("touchmove", handleTouchMove);

      // Clear any old click handlers in case this is the start of an ordinary click.
      element.removeEventListener("click", handleClick, true);
    }

    var image = event.target.closest("img");
    if (image) {
      data.image = image.src;
    }

    if (element || image) {
      var touch = event.touches[0];
      touchDownX = touch.screenX;
      touchDownY = touch.screenY;

      longPressTimeout = setTimeout(function() {
        touchHandled = true;
        cancel();
        if (element) {
          element.addEventListener("click", handleClick, true);
        }
        webkit.messageHandlers.contextMenuMessageHandler.postMessage(data);
      }, 500);

      webkit.messageHandlers.contextMenuMessageHandler.postMessage({ handled: true });
    }
  });
}, true);

// If the user touches down and moves enough to make the page scroll, cancel the
// context menu handlers.
addEventListener("scroll", cancel);

})();
