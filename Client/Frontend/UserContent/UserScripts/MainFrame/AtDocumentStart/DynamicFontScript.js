
"use strict";

Object.defineProperty(window.__firefox__, "dynamicFonts", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: Object.freeze({
        setStyle: setStyle
    })
});

var currentStyle = null;

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
