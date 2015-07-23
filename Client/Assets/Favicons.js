/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
 // These integers should be kept in sync with the IconType raw-values
 var ICON = 0;
 var APPLE = 1;
 var APPLE_PRECOMPOSED = 2;
 var GUESS = 3;
 var OPENGRAPH = 6;

 function resolve(href) {
   var a = document.createElement("a");
   a.setAttribute("href", href);
   return a.href;
 }

 var Favicons = {
 selectors: { "meta[property='og:image']" : { type: OPENGRAPH, attribute: "content" },
              "link[rel~='icon']": { type: ICON, attribute: "href" },
              "link[rel='apple-touch-icon']" : { type: APPLE, attribute: "href" },
              "link[rel='apple-touch-icon-precomposed']" : { type: APPLE_PRECOMPOSED, attribute: "href" },
 },

 getAll: function() {
    var res = {}
    var foundIcons = false

    for (selector in this.selectors) {
      var data = this.selectors[selector];
      var icons = document.querySelectorAll(selector)

      for (var i = 0; i < icons.length; i++) {
        var href = icons[i].getAttribute(data.attribute);
        res[resolve(href)] = data.type;

        if (!foundIcons && data.type == ICON) {
          foundIcons = true
        }
      }
    }

    // If we didn't find anything in the page, look to see if a favicon.ico file exists for the domain
    if (res) {
      var href = document.location.origin + "/favicon.ico";
      res[resolve("/favicon.ico")] = GUESS;
    }

    return res;
  }
}

window.addEventListener("load", function() {
  var favicons = Favicons.getAll();
  webkit.messageHandlers.faviconsMessageHandler.postMessage(favicons);
});

})()