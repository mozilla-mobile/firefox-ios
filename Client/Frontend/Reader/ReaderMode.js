/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var _firefox_ReaderMode = {
    // If this is http or https content, and not an index page, then try to run Readability. If anything
    // fails, the app will never be notified and we don't show the button. That is ok for now since there
    // is no error feedback possible anyway.

    readabilityResult: null,

    checkReadability: function() {
        if ((document.location.protocol === "http:" || document.location.protocol === "https:") && document.location.pathname !== "/") {
            // Short circuit in case we already ran Readability. This mostly happens when going
            // back/forward: the page will be cached and the result will still be there.
            if (_firefox_ReaderMode.readabilityResult && _firefox_ReaderMode.readabilityResult.content) {
                webkit.messageHandlers.readerModeMessageHandler.postMessage("Available");
            } else {
                var uri = {
                    spec: document.location.href,
                    host: document.location.host,
                    prePath: document.location.protocol + "//" + document.location.host, // TODO This is incomplete, needs username/password and port
                    scheme: document.location.protocol,
                    pathBase: document.location.protocol + "//" + document.location.host + location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1)
                }
                var readability = new Readability(uri, document.cloneNode(true));
                _firefox_ReaderMode.readabilityResult = readability.parse();
                webkit.messageHandlers.readerModeMessageHandler.postMessage(_firefox_ReaderMode.readabilityResult !== null ? "Available" : "Unavailable");
            }
        } else if (document.location.protocol === "about:" && document.location.pathname === "reader") {
            webkit.messageHandlers.readerModeMessageHandler.postMessage("Active");
        } else {
            webkit.messageHandlers.readerModeMessageHandler.postMessage("Unavailable");
        }
    },

    simplifyReaderDomain: function(domain) {
        domain = domain.toLowerCase();
        if (domain.indexOf("www.") == 0) {
            domain = domain.substring(4);
        } else if (domain.indexOf("m.") == 0) {
            domain = domain.substring(2);
        } else if (domain.indexOf("mobile.") == 0) {
            domain = domain.substring(7);
        }
        return domain;
    },

    readerize: function(style) {
        if (_firefox_ReaderMode.readabilityResult) {
            var template = _firefox_ReaderMode.readerModeTemplate();
            template = template.replace("%READER-STYLE%", JSON.stringify(style));
            template = template.replace("%READER-DOMAIN%", _firefox_ReaderMode.simplifyReaderDomain(_firefox_ReaderMode.readabilityResult.uri.host));
            template = template.replace("%READER-URL%", _firefox_ReaderMode.readabilityResult.uri.spec || "");
            template = template.replace("%READER-CONTENT%", _firefox_ReaderMode.readabilityResult.content || "");
            template = template.replace("%READER-TITLE%", _firefox_ReaderMode.readabilityResult.title || "");
            template = template.replace("%READER-CREDITS%", _firefox_ReaderMode.readabilityResult.byline || "");
            return template;
        }
    },

    // This is inline here because I don't have a good answer just yet about loading non-js content into
    // the sandboxed javascript world. This is far from ideal but will be addressed in a next iteration.
    // The CSS is currently linked to a remote site. This will be fixed as part of bug 1123408.

    readerModeTemplate: function() {
        var template = '';
        template += '<!DOCTYPE html>\n';
        template += '<html>\n';
        template += '\n';
        template += '<head>\n';
        template += '  <meta content="text/html; charset=UTF-8" http-equiv="content-type">\n';
        template += '  <meta name="viewport" content="width=device-width, user-scalable=no" />\n';
        template += '  <link rel="stylesheet" href="http://wopr.norad.org/~stefan/Reader.css" type="text/css"/>\n';
        template += '  <script type="">var _firefox_ReaderPage = { style: %READER-STYLE% };</script>\n';
        template += '</head>\n';
        template += '\n';
        template += '<body>\n';
        template += '  <div id="reader-header" class="header">\n';
        template += '    <a id="reader-domain" class="domain" href="%READER-URL%">%READER-DOMAIN%</a>\n';
        template += '    <div class="domain-border"></div>\n';
        template += '    <h1 id="reader-title">%READER-TITLE%</h1>\n';
        template += '    <div id="reader-credits" class="credits">%READER-CREDITS%</div>\n';
        template += '  </div>\n';
        template += '\n';
        template += '  <div id="reader-content" class="content">\n';
        template += '    %READER-CONTENT%\n';
        template += '  </div>\n';
        template += '\n';
        template += '  <div id="reader-message" class="message">\n';
        template += '    %READER-MESSAGE%\n';
        template += '  </div>\n';
        template += '\n';
        template += '  <ul id="reader-toolbar" class="toolbar toolbar-hidden">\n';
        template += '    <li><a id="share-button" class="button share-button" href="#"></a></li>\n';
        template += '    <ul class="dropdown">\n';
        template += '      <li><a class="dropdown-toggle button style-button" href="#"></a></li>\n';
        template += '      <li class="dropdown-popup">\n';
        template += '        <ul id="font-type-buttons"></ul>\n';
        template += '        <hr></hr>\n';
        template += '        <ul id="font-size-buttons" class="segmented-button"></ul>\n';
        template += '        <hr></hr>\n';
        template += '        <ul id="color-scheme-buttons" class="segmented-button"></ul>\n';
        template += '      </li>\n';
        template += '    </ul>\n';
        template += '    <li><a id="toggle-button" class="button toggle-button" href="#"></a></li>\n';
        template += '  </ul>\n';
        template += '\n';
        template += '</body>\n';
        template += '\n';
        template += '</html>\n';
        return template;
    },
    
    // TODO The following code only makes sense in about:reader context. It may be a good idea to move
    //   it out of this file and into for example a Reader.js.
    
    currentStyle: null,
    
    setStyle: function(style) {
        // Configure the theme (light, dark)
        if (_firefox_ReaderMode.currentStyle != null) {
            document.body.classList.remove(_firefox_ReaderMode.currentStyle.theme);
        }
        document.body.classList.add(style.theme);
        
        // Configure the font size (1-5)
        if (_firefox_ReaderMode.currentStyle != null) {
            document.body.classList.remove("font-size" + currentStyle.fontSize);
        }
        document.body.classList.add("font-size" + style.fontSize);

        // Configure the font type
        if (_firefox_ReaderMode.currentStyle != null) {
            document.body.classList.remove(currentStyle.fontType);
        }
        document.body.classList.add(style.fontType);
        
        // Remember the style
        _firefox_ReaderMode.currentStyle = style;
    },

    _BLOCK_IMAGES_SELECTOR: ".content p > img:only-child, " +
        ".content p > a:only-child > img:only-child, " +
        ".content .wp-caption img, " +
        ".content figure img",
    
    updateImageMargins: function() {
        var contentElement = document.getElementById('reader-content');
        
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
            
            var cssText = "max-width: " + maxWidthStyle + ";" +
                "width: " + widthStyle + ";" +
                "margin-left: " + imageStyle + ";" +
                "margin-right: " + imageStyle + ";";
            
            img.style.cssText = cssText;
        }
        
        var imgs = document.querySelectorAll(_firefox_ReaderMode._BLOCK_IMAGES_SELECTOR);
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
    },
    
    showContent: function() {
        // Make the reader visible
        var messageElement = document.getElementById('reader-message');
        messageElement.style.display = "none";
        var headerElement = document.getElementById('reader-header');
        headerElement.style.display = "block"
        var contentElement = document.getElementById('reader-content');
        contentElement.style.display = "block";
    },
    
    configureReader: function() {
        // Configure the reader with the initial style that was injected in the page.
        _firefox_ReaderMode.setStyle(_firefox_ReaderPage.style);

        // The order here is important. Because updateImageMargins depends on contentElement.offsetWidth which
        // will not be set until contentElement is visible. If this leads to annoying content reflowing then we
        // need to look at an alternative way to do this.
        _firefox_ReaderMode.showContent();
        _firefox_ReaderMode.updateImageMargins();
    }
};

window.addEventListener('load', function(event) {
    // If this is an about:reader page that we are loading, apply the initial style to the page.
    if (document.location.protocol === "about:" && document.location.pathname === "reader") {
        _firefox_ReaderMode.configureReader();
    }
});

window.addEventListener('pageshow', function(event) {
    _firefox_ReaderMode.checkReadability();
});
