/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {

const GESTURE_ALLOWABLE_MOVEMENT = 10;
const GESTURE_MINIMUM_PRESS_DURATION = 500;

const SUPPRESS_NEXT_CLICK_DURATION = 50;

var target = null;
var originalTargetTouchCalloutStyle = '';

var didLongPress = false;
var longPressTimeout = null;

var touchstartScreenX = 0;
var touchstartScreenY = 0;

window.addEventListener('touchstart', function(evt) {
  // Get the closest applicable target element. If the `touchstart`
  // event did not occur on an `<a>` or `<img>` element or the target
  // element does not contain one in its parent DOM tree, bail out to
  // prevent further detection for the long-press gesture.
  target = evt.target.closest('a,img');
  if (!target) {
    return;
  }

  // Let `ContextMenuHelper` know that we're handling a potential
  // long-press gesture for an `<a>` or `<img>` element.
  webkit.messageHandlers.contextMenuMessageHandler.postMessage({ longPressStarted: true });

  // Remember the original `-webkit-touch-callout` style for the
  // closest applicable target element so we can restore it later.
  originalTargetTouchCalloutStyle = target.style.webkitTouchCallout;

  // Check if the closest applicable target element has the
  // `-webkit-touch-callout` CSS property set to `none`. If so,
  // bail out to prevent the context menu from appearing.
  if (originalTargetTouchCalloutStyle === 'none') {
    return;
  }

  // Set the `-webkit-touch-callout` style for the closest applicable
  // target element to `none` to prevent the native `WKWebView`
  // context menu from appearing.
  target.style.webkitTouchCallout = 'none';

  // Remember the starting `screenX` and `screenY` positions for the
  // touch event so we can cancel the gesture if the user moves the
  // touch past the threshold.
  touchstartScreenX = evt.touches[0].screenX;
  touchstartScreenY = evt.touches[0].screenY;

  // Reset our flag indicating if a long-press gesture has occurred
  // so we can suppress the next `click` event only after we have
  // completed a long-press gesture.
  didLongPress = false;

  // Wait till the next tick before continuing to check for the gesture
  // to give page scripts a chance to `preventDefault()` to prevent the
  // context menu from appearing.
  setTimeout(function() {
    if (evt.defaultPrevented) {
      cancel();
      return;
    }

    // Wait for the minimum long-press duration before handling the gesture.
    longPressTimeout = setTimeout(handleLongPress, GESTURE_MINIMUM_PRESS_DURATION, evt.target);
  });

  // Add event listeners to the `window` for `touchmove`, `touchend`, and
  // `scroll` events.
  window.addEventListener('touchmove', ontouchmove);
  window.addEventListener('touchend', ontouchend);
  window.addEventListener('scroll', onscroll);
}, true);

function ontouchmove(evt) {
  if (Math.abs(touchstartScreenX - evt.touches[0].screenX) > GESTURE_ALLOWABLE_MOVEMENT ||
      Math.abs(touchstartScreenY - evt.touches[0].screenY) > GESTURE_ALLOWABLE_MOVEMENT) {
    cancel();
  }
}

function ontouchend(evt) {
  // If a long-press gesture was detected, suppress the next `click`
  // event on the page to prevent unintended navigation.
  if (didLongPress) {
    suppressNextClick();
  }

  cancel();
}

function onscroll(evt) {
  cancel();
}

function handleLongPress(originalTarget) {
  didLongPress = true;
  longPressTimeout = null;

  var data = {};

  var targetLink = originalTarget.closest('a');
  if (targetLink) {
    data.link = targetLink.href;
  }

  var targetImage = originalTarget.closest('img');
  if (targetImage) {
    data.image = targetImage.src;
  }

  // Let `ContextMenuHelper` know which `<a>` and/or `<img>` elements
  // the long-press gesture occurred on.
  webkit.messageHandlers.contextMenuMessageHandler.postMessage(data);

  // Suppress the next `click` event on the page to prevent unintended
  // navigation.
  suppressNextClick();
  cancel();
}

function cancel() {
  if (longPressTimeout) {
    clearTimeout(longPressTimeout);
  }

  didLongPress = false;

  touchstartScreenX = 0;
  touchstartScreenY = 0;

  // Clean up the `window` event listeners.
  window.removeEventListener('touchmove', ontouchmove);
  window.removeEventListener('touchend', ontouchend);
  window.removeEventListener('scroll', onscroll);

  // Restore the original `-webkit-touch-callout` style for the
  // closest applicable target element.
  if (target) {
    target.style.webkitTouchCallout = originalTargetTouchCalloutStyle;
  }
}

function suppressNextClick() {
  document.addEventListener('click', onclick);

  var suppressNextClickTimeout = setTimeout(function() {
    document.removeEventListener('click', onclick);
  }, SUPPRESS_NEXT_CLICK_DURATION);

  function onclick(evt) {
    evt.preventDefault();
    document.removeEventListener('click', onclick);
    clearTimeout(suppressNextClickTimeout);
  }
}

})();
