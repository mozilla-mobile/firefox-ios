/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";
import { isProbablyReaderable, Readability } from "@mozilla/readability";

const DEBUG = false;

var readabilityResult = null;
var currentStyle = null;

const readerModeURL = /^http:\/\/localhost:\d+\/reader-mode\/page/;

const BLOCK_IMAGES_SELECTOR =
  ".content p > img:only-child, " +
  ".content p > a:only-child > img:only-child, " +
  ".content .wp-caption img, " +
  ".content figure img";

function debug(s) {
  if (!DEBUG) {
    return;
  }
  console.log(s);
}

function checkReadability() {
  setTimeout(function() {
    if (document.location.href.match(readerModeURL)) {
      debug({Type: "ReaderModeStateChange", Value: "Active"});
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Active"});
      return;
    }

    if(!isProbablyReaderable(document)) {
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
      return;
    }

    if ((document.location.protocol === "http:" || document.location.protocol === "https:") && document.location.pathname !== "/") {
      // Short circuit in case we already ran Readability. This mostly happens when going
      // back/forward: the page will be cached and the result will still be there.
      if (readabilityResult && readabilityResult.content) {
        debug({Type: "ReaderModeStateChange", Value: "Available"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Available"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderContentParsed", Value: readabilityResult});
        return;
      }

      var uri = {
        spec: document.location.href,
        host: document.location.host,
        prePath: document.location.protocol + "//" + document.location.host, // TODO This is incomplete, needs username/password and port
        scheme: document.location.protocol.substr(0, document.location.protocol.indexOf(":")),
        pathBase: document.location.protocol + "//" + document.location.host + location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1)
      }

      // document.cloneNode() can cause the webview to break (bug 1128774).
      // Serialize and then parse the document instead.
      var docStr = new XMLSerializer().serializeToString(document);

      // Do not attempt to parse DOM if this document contains a <frameset/>
      // element. This causes the WKWebView content process to crash (Bug 1489543).
      if (docStr.indexOf("<frameset ") > -1) {
        debug({Type: "ReaderModeStateChange", Value: "Unavailable"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
        return;
      }

      const DOMPurify = require('dompurify');
      const clean = DOMPurify.sanitize(docStr, {WHOLE_DOCUMENT: true});
      var doc = new DOMParser().parseFromString(clean, "text/html");
      var readability = new Readability(uri, doc, { debug: DEBUG });
      readabilityResult = readability.parse();

      if (!readabilityResult) {
        debug({Type: "ReaderModeStateChange", Value: "Unavailable"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
        return;
      }

      // Sanitize the title to prevent a malicious page from inserting HTML in the `<title>`.
      readabilityResult.title = escapeHTML(readabilityResult.title);
      // Sanitize the byline to prevent a malicious page from inserting HTML in the `<byline>`.
      readabilityResult.byline = escapeHTML(readabilityResult.byline);

      debug({Type: "ReaderModeStateChange", Value: readabilityResult !== null ? "Available" : "Unavailable"});
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: readabilityResult !== null ? "Available" : "Unavailable"});
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderContentParsed", Value: readabilityResult});
      return;
    }

    debug({Type: "ReaderModeStateChange", Value: "Unavailable"});
    webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
  }, 100);
}

// Readerize the document. Since we did the actual readerization already in checkReadability, we
// can simply return the results we already have.
function readerize() {
  return readabilityResult;
}

// TODO: The following code only makes sense in about:reader context. It may be a good idea to move
// it out of this file and into for example a Reader.js.

function setStyle(style) {
  // Configure the theme (light, dark)
  if (currentStyle && currentStyle.theme) {
    document.body.classList.remove(currentStyle.theme);
  }
  if (style && style.theme) {
    document.body.classList.add(style.theme);
  }

  // Configure the font size (1-5)
  if (currentStyle && currentStyle.fontSize) {
    document.body.classList.remove("font-size" + currentStyle.fontSize);
  }
  if (style && style.fontSize) {
    document.body.classList.add("font-size" + style.fontSize);
  }

  // Configure the font type
  if (currentStyle && currentStyle.fontType) {
    document.body.classList.remove(currentStyle.fontType);
  }
  if (style && style.fontType) {
    document.body.classList.add(style.fontType);
  }

  // Remember the style
  currentStyle = style;
}

function updateImageMargins() {
  var contentElement = document.getElementById("reader-content");
  if (!contentElement) {
    return;
  }

  var windowWidth = window.innerWidth;
  var contentWidth = contentElement.offsetWidth;
  var maxWidthStyle = windowWidth + "px !important";

  var setImageMargins = function(img) {
    if (!img._originalWidth) {
      img._originalWidth = img.offsetWidth;
    }

    var imgWidth = img._originalWidth;

    // If the image is taking more than half of the screen, just make
    // it fill edge-to-edge.
    if (imgWidth < contentWidth && imgWidth > windowWidth * 0.55) {
      imgWidth = windowWidth;
    }

    var sideMargin = Math.max((contentWidth - windowWidth) / 2, (contentWidth - imgWidth) / 2);

    var imageStyle = sideMargin + "px !important";
    var widthStyle = imgWidth + "px !important";

    var cssText =
      "max-width: " + maxWidthStyle + ";" +
      "width: " + widthStyle + ";" +
      "margin-left: " + imageStyle + ";" +
      "margin-right: " + imageStyle + ";";

    img.style.cssText = cssText;
  };

  var imgs = document.querySelectorAll(BLOCK_IMAGES_SELECTOR);
  for (var i = imgs.length; --i >= 0;) {
    var img = imgs[i];
    if (img.width > 0) {
      setImageMargins(img);
    } else {
      img.onload = function() {
        setImageMargins(img);
      }
    }
  }
}

function showContent() {
  // Make the reader visible
  var messageElement = document.getElementById("reader-message");
  if (messageElement) {
    messageElement.style.display = "none";
  }
  var headerElement = document.getElementById("reader-header");
  if (headerElement) {
    headerElement.style.display = "block"
  }
  var contentElement = document.getElementById("reader-content");
  if (contentElement) {
    contentElement.style.display = "block";
  }
}

function configureReader() {
  // Configure the reader with the initial style that was injected in the page.
  var style = JSON.parse(document.body.getAttribute("data-readerStyle"));
  setStyle(style);

  // The order here is important. Because updateImageMargins depends on contentElement.offsetWidth which
  // will not be set until contentElement is visible. If this leads to annoying content reflowing then we
  // need to look at an alternative way to do
  showContent();
  updateImageMargins();
}

function escapeHTML(string) {
  if (typeof(string) !== 'string') { return ''; }
  return string
    .replace(/\&/g, "&amp;")
    .replace(/\</g, "&lt;")
    .replace(/\>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/\'/g, "&#039;");
}

Object.defineProperty(window.__firefox__, "reader", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze({
    checkReadability: checkReadability,
    readerize: readerize,
    setStyle: setStyle
  })
});

window.addEventListener("load", function(event) {
  // If this is an about:reader page that we are loading, apply the initial style to the page.
  if (document.location.href.match(readerModeURL)) {
    configureReader();
  }
});

window.addEventListener("pageshow", function(event) {
  // If this is an about:reader page that we are showing, fire an event to the native code
  if (document.location.href.match(readerModeURL)) {
    webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderPageEvent", Value: "PageShow"});
  }
});
