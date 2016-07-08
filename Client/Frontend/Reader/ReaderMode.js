/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var _firefox_ReaderMode = {
    // If this is http or https content, and not an index page, then try to run Readability. If anything
    // fails, the app will never be notified and we don't show the button. That is ok for now since there
    // is no error feedback possible anyway.

    readabilityResult: null,

    DEBUG: false,

    debug: function(s) {
        if (!this.DEBUG) {
            return;
        }
        console.log(s);
    },

    checkReadability: function() {
        if (document.location.href.match(/^http:\/\/localhost:\d+\/reader-mode\/page/)) {
            this.debug({Type: "ReaderModeStateChange", Value: "Active"});
            webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Active"});
            return;
        }

        if ((document.location.protocol === "http:" || document.location.protocol === "https:") && document.location.pathname !== "/") {
            // Short circuit in case we already ran Readability. This mostly happens when going
            // back/forward: the page will be cached and the result will still be there.
            if (_firefox_ReaderMode.readabilityResult && _firefox_ReaderMode.readabilityResult.content) {
                this.debug({Type: "ReaderModeStateChange", Value: "Available"});
                webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Available"});
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
            var doc = new DOMParser().parseFromString(docStr, "text/html");
            var readability = new Readability(uri, doc);
            _firefox_ReaderMode.readabilityResult = readability.parse();

            this.debug({Type: "ReaderModeStateChange", Value: _firefox_ReaderMode.readabilityResult !== null ? "Available" : "Unavailable"});
            webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: _firefox_ReaderMode.readabilityResult !== null ? "Available" : "Unavailable"});

            return;
        }

        this.debug({Type: "ReaderModeStateChange", Value: "Unavailable"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
    },

    // Readerize the document. Since we did the actual readerization already in checkReadability, we
    // can simply return the results we already have.

    readerize: function() {
        return _firefox_ReaderMode.readabilityResult;
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
            document.body.classList.remove("font-size" + _firefox_ReaderMode.currentStyle.fontSize);
        }
        document.body.classList.add("font-size" + style.fontSize);

        // Configure the font type
        if (_firefox_ReaderMode.currentStyle != null) {
            document.body.classList.remove(_firefox_ReaderMode.currentStyle.fontType);
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
        var style = JSON.parse(document.body.getAttribute("data-readerStyle"));
        _firefox_ReaderMode.setStyle(style);

        // The order here is important. Because updateImageMargins depends on contentElement.offsetWidth which
        // will not be set until contentElement is visible. If this leads to annoying content reflowing then we
        // need to look at an alternative way to do this.
        _firefox_ReaderMode.showContent();
        _firefox_ReaderMode.updateImageMargins();
    },

    dictation: {

    	reference: null,

    	anchors: null,

    	scrolling: {

    		motion: new Array(2).fill(0),

    		magnitude: null,

    		target: null,

    		interval: setInterval(function () {
    			var scrolling = _firefox_ReaderMode.dictation.scrolling;
    			if (scrolling.target === null) {
    				return;
    			}
    			var difference = scrolling.target - window.scrollY;
    			if (difference !== 0) {
    				scrolling.motion[scrolling.motion.length - 1] = window.scrollY < scrolling.target ? scrolling.magnitude : -scrolling.magnitude;
    				for (var order = scrolling.motion.length - 2; order >= 0; -- order) {
    					scrolling.motion[order] += scrolling.motion[order + 1];
    				}
    				var displacement = Math.min(Math.abs(difference), Math.abs(scrolling.motion[0])) * Math.sign(scrolling.motion[0]);
    				if (window.scrollY + displacement === scrolling.target) {
    					scrolling.motion.fill(0);
    				}
    				window.scrollTo(window.scrollX, window.scrollY + displacement);
    			}
    		}, 1000 / 60)

    	},

    	extractContentText: function () {
			var contentText = "";
			var anchors = this.anchors = [];
			var reference = this.reference = {};
		    var extract = function (node, content) {
		    	for (var child of Array.prototype.slice.call(node.childNodes)) {
		    		switch (child.nodeType) {
			            case Node.ELEMENT_NODE:
			            	// Content elements that we want to read from (this excludes some tags, such as <sup> to avoid reading citations)
			            	var blockElements = ["DIV", "P"], inlineElements = ["B", "I", "A"];
			            	if (blockElements.indexOf(child.tagName) !== -1 || inlineElements.indexOf(child.tagName) !== -1) {
			            		extract(child, content);
			            	}
			            	if (blockElements.indexOf(child.tagName) !== -1 && contentText.slice(-1) !== "\n" && !/^\s+$/.test(child.textContent)) {
			            		contentText += "\n";
			            	}
			            	break;
			            case Node.TEXT_NODE:
			            	if (!/^\s+$/.test(child.textContent)) {
			            		var wrapper = document.createElement("span");
			            		wrapper.classList.add("dictation-wrapper");
			            		node.insertBefore(wrapper, child);
			            		wrapper.appendChild(child);
				            	anchors.push(contentText.length);
				            	reference[anchors[anchors.length - 1]] = wrapper;
				            	contentText += child.textContent;
			            	}
			            	break;
			        }
		    	}
		    }
		    extract(document.querySelector("#reader-content"));
		    return contentText;
		},

		markDictatedContent: function (start, end, scrollToViewDictation) {
			if (this.reference === null) {
				return;
			}
			var throughAnchors = [this.anchors.reduce(function (previous, next) { return next <= start ? next : previous; })].concat(this.anchors.filter(function (x) { return x > start && x < end; }));
			for (var dictating of Array.prototype.slice.call(document.querySelectorAll(".dictating"))) {
				dictating.parentNode.textContent = dictating.parentNode.textContent;
			}
			for (var anchor of throughAnchors) {
				var contained = this.reference[anchor];
				var preDictation = document.createElement("span"), dictation = document.createElement("span"), postDictation = document.createElement("span");
				dictation.classList.add("dictating");
				var textContent = contained.textContent;
				contained.textContent = "";
				preDictation.textContent = textContent.substring(0, start - anchor);
				dictation.textContent = textContent.substring(start - anchor, end - anchor);
				postDictation.textContent = textContent.substring(end - anchor);
				for (var element of [preDictation, dictation, postDictation]) {
					contained.appendChild(element);
				}
			}
			this.setScrollToDictationOn(scrollToViewDictation);
		},

		setScrollToDictationOn: function (on) {
			// The higher the scaling, the slower the acceleration will be
			var SCROLLING_SPEED_SCALING = 100;
			if (on) {
				var elements = Array.prototype.slice.call(document.querySelectorAll(".dictating"));
				if (elements.length > 0) {
					var scrollPosition = elements.reduce(function (sum, dictation) { return sum + dictation.getBoundingClientRect().top }, 0);
					this.scrolling.target = scrollPosition / elements.length + window.scrollY - window.innerHeight / 2;
					this.scrolling.magnitude = Math.abs(window.scrollY - this.scrolling.target) / SCROLLING_SPEED_SCALING;
				} else {
					on = false;
				}
			}
			if (!on) {
				this.scrolling.motion.fill(0);
				this.scrolling.target = null;
			}
		}

    }

};

window.addEventListener('load', function(event) {
    // If this is an about:reader page that we are loading, apply the initial style to the page.
    if (document.location.href.match(/^http:\/\/localhost:\d+\/reader-mode\/page/)) {
        _firefox_ReaderMode.configureReader();
    }
});


window.addEventListener('pageshow', function(event) {
    // If this is an about:reader page that we are showing, fire an event to the native code
    if (document.location.href.match(/^http:\/\/localhost:\d+\/reader-mode\/page/)) {
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderPageEvent", Value: "PageShow"});
    }
});
