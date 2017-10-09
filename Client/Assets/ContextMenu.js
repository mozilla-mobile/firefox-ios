///* This Source Code Form is subject to the terms of the Mozilla Public
// * License, v. 2.0. If a copy of the MPL was not distributed with this
// * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
  target = evt.target.closest('a,img');
  if (!target) {
    return;
  }

  if (getComputedStyle(target).webkitTouchCallout === 'none') {
    return;
  }

  originalTargetTouchCalloutStyle = target.style.webkitTouchCallout;
  target.style.webkitTouchCallout = 'none';

  touchstartScreenX = evt.touches[0].screenX;
  touchstartScreenY = evt.touches[0].screenY;

  didLongPress = false;

  // Wait till the next tick before continuing to check for the gesture
  // to give page scripts a change to `preventDefault()` to prevent the
  // context menu from appearing.
  setTimeout(function() {
    if (evt.defaultPrevented) {
      cancel();
      return;
    }

    longPressTimeout = setTimeout(function() {
      didLongPress = true;
      longPressTimeout = null;

      var data = {};

      var targetLink = evt.target.closest('a');
      if (targetLink) {
        data.link = targetLink.href;
      }

      var targetImage = evt.target.closest('img');
      if (targetImage) {
        data.image = targetImage.src;
      }

      webkit.messageHandlers.contextMenuMessageHandler.postMessage(data);

      suppressNextClick();
      cancel();
    }, GESTURE_MINIMUM_PRESS_DURATION);
  });

  window.addEventListener('touchmove', ontouchmove);
  window.addEventListener('touchend', ontouchend);
  window.addEventListener('scroll', onscroll);

  webkit.messageHandlers.contextMenuMessageHandler.postMessage({ handled: true });
}, true);

function ontouchmove(evt) {
  if (Math.abs(touchstartScreenX - evt.touches[0].screenX) > GESTURE_ALLOWABLE_MOVEMENT ||
      Math.abs(touchstartScreenY - evt.touches[0].screenY) > GESTURE_ALLOWABLE_MOVEMENT) {
    cancel();
  }
}

function ontouchend(evt) {
  if (didLongPress) {
    suppressNextClick();
  }

  cancel();
}

function onscroll(evt) {
  cancel();
}

function cancel() {
  if (longPressTimeout) {
    clearTimeout(longPressTimeout);
  }

  didLongPress = false;

  touchstartScreenX = 0;
  touchstartScreenY = 0;

  window.removeEventListener('touchmove', ontouchmove);
  window.removeEventListener('touchend', ontouchend);
  window.removeEventListener('scroll', onscroll);

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
