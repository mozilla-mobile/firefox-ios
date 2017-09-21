/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
(function() {
  "use strict";

  function ImageOverlayer() {
    function create(element) {
      // Create a parent element to hold each highlight rect.
      // This allows us to set the opacity for the entire highlight
      // without worrying about overlapping opacities for each child.
      var highlightDiv = document.createElement("div");
      highlightDiv.style.pointerEvents = "none";
      highlightDiv.style.top = "0px";
      highlightDiv.style.left = "0px";
      highlightDiv.style.position = "absolute";
      highlightDiv.style.opacity = 0.1;
      highlightDiv.style.zIndex = 99999;

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

      return highlightDiv
    }

    return {
      create: create
    }
  }

  function ImageFinder() {
    function find(element) {
      var element = element;
      var data = {}
      do {
        if (!data.link && element.localName === "a") {
          data.link = element.href;
          data.linkElement = element;
        }
  
        if (!data.image && element.localName === "img") {
          data.image = element.src;
          data.imageElement = element;
        }
  
        element = element.parentElement;
      } while (element);

      return data;
    }

    return {
      find: find
    }
  }

  function LinkBuilder() {
    function build(data) {
      var url = "";
      var isFirstParameter = true;
      var objectKeys = Object.keys(data);
      for (var i = 0; i < objectKeys.length; i++) {
        url += (isFirstParameter ? "?" : "&");
        url += (objectKeys[i] + "=" + data[objectKeys[i]]);
        isFirstParameter = false;
      }

      return "focusmessage://" + url;
    }

    return {
      build: build
    }
  }

  function LongPressCoordinator() {

    var _cancelClick = false;
    var _imageFinder = new ImageFinder();
    var _imageOverlayer = new ImageOverlayer();
    var _imageOverlay = null;
    var _linkElement = null;
    var _linkBuilder = new LinkBuilder();
    var _longPressDuration = 500;
    var _longPressTimeout = null;
    var _MAX_RADIUS = 9;
    var _touch = null;
    var _touchHandled = false;

    function handleClick(event) {
      if (_cancelClick) {
        event.preventDefault();
        _cancelClick = false;
      }

      if (_linkElement) {
        _linkElement.removeEventListener("click", handleClick);
        _linkElement = null;
      }
    }

    function handleTouchEnd(event) {
      removeEventListener('touchmove', handleTouchMove);
      removeEventListener('touchend', handleTouchEnd);

      if (_touchHandled) {
        _touchHandled = false;
        event.preventDefault();
      } else {
        _cancelClick = false;
      }      

      reset();
    }

    function handleTouchMove(event) {
      if (isBusy()) {
        var { screenX, screenY } = event.touches[0];
        if (Math.abs(_touch.screenX - screenX) > _MAX_RADIUS || Math.abs(_touch.screenY - screenY) > _MAX_RADIUS) {
          reset();
        }
      }
    }

    function reset() {
      if (!isBusy()) { return; }
      clearTimeout(_longPressTimeout);

      if (_imageOverlay) {
        document.body.removeChild(_imageOverlay);
        _imageOverlay = null;
      }

      _longPressTimeout = null;
    }

    function register(element, touch) {
      if (isBusy()) { return; }

      var data = _imageFinder.find(element)
      if (!data.image) { return; }
      
      var overlay = _imageOverlayer.create(data.imageElement);
      document.body.appendChild(overlay);
      _imageOverlay =  overlay;




      var url = _linkBuilder.build(data);
      _touch = touch
      

      element.addEventListener("touchend", handleTouchEnd);
      element.addEventListener("touchmove", handleTouchMove);

      _linkElement = data.linkElement;
      if (_linkElement) {
        _linkElement.addEventListener("click", handleClick);
      }

      _longPressTimeout = setTimeout(function() {
        _cancelClick = true;
        _touchHandled = true;

        window.location = url;
        reset()
      }, _longPressDuration);
    }

    function isBusy() {
      return _longPressTimeout != null;
    }

    return {
      isBusy: isBusy,
      register: register,
      reset: reset
    }
  }

  var longPressCoordinator = new LongPressCoordinator();

  addEventListener("touchstart", function(event) {
    if (longPressCoordinator.isBusy()) { return; }

    if (event.defaultPrevented || event.touches.length !== 1) {
      longPressCoordinator.reset()
      return;
    }

    var element = event.target;
    var touch = event.touches[0]
    var style = getComputedStyle(element);

    if (style.webkitTouchCallout === "none") {
      return;
    }

    longPressCoordinator.register(element, touch);
  });

  addEventListener("scroll", longPressCoordinator.reset)

})();