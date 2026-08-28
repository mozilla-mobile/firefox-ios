// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

var isFullScreenEnabled = document.fullscreenEnabled ||
                                    document.webkitFullscreenEnabled ||
                                    document.mozFullScreenEnabled ||
                                    document.msFullscreenEnabled ? true : false;

var isFullscreenVideosSupported = HTMLVideoElement.prototype.webkitEnterFullscreen !== undefined;

if (!isFullScreenEnabled && isFullscreenVideosSupported && !/mobile/i.test(navigator.userAgent)) {
    
    HTMLElement.prototype.requestFullscreen = function() {
        if (this.webkitRequestFullscreen !== undefined) {
            this.webkitRequestFullscreen();
            return true;
        }
        
        if (this.webkitEnterFullscreen !== undefined) {
            this.webkitEnterFullscreen();
            return true;
        }
        
        var video = this.querySelector("video")
        if (video !== undefined) {
            video.webkitEnterFullscreen();
            return true;
        }
        return false;
    };
    
    Object.defineProperty(document, 'fullscreenEnabled', {
        get: function() {
            return true;
        }
    });
    
    Object.defineProperty(document.documentElement, 'fullscreenEnabled', {
        get: function() {
            return true;
        }
    });
}

/// creating a `<video>` without `playsinline/webkit-playsinline`
/// that also has `autoplay` will cause it to play fullscreen by default.
/// In order to prevent this we monkey-patch `document.createElement` to add
/// `playsinline` to every newly created `<video>` element.
/// This is a good default because it makes videos less intrusive.
/// Calling `requestFullscreen()` on the video element still works as expected and
/// the user can still enter full screen by interacting with the video controls.
/// FXIOS-12482 has more details on this issue.

const forceInline = (video) => {
  const inlineAttributes = ["playsinline", "webkit-playsinline"];
  inlineAttributes.forEach((attr) => {
    if (!video.hasAttribute(attr)) {
      video.setAttribute(attr, "");
    }
  });
};

const originalCreateElement = document.createElement;
document.createElement = function (tag) {
  const el = originalCreateElement.call(this, tag);
  if (el.localName === "video") {
    forceInline(el);
  }
  return el;
};
