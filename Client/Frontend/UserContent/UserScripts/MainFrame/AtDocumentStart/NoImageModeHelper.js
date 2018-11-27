/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";
/*
 var noImageCSS = "*{background-image:none !important;}img,iframe{visibility:hidden !important;}body{background-color:#000044;} #divSupported{position:fixed;top:0px;width:100%;background-color:#000;color:#fff;text-align:center;size:25px;height:90px;z-index:9999999999;padding:10px;}#buttonSupported{-moz-box-shadow: 0px 1px 0px 0px #fff6af;    -webkit-box-shadow: 0px 1px 0px 0px #fff6af;    box-shadow: 0px 1px 0px 0px #fff6af;    background:-webkit-gradient(linear, left top, left bottom, color-stop(0.05, #ffec64), color-stop(1, #ffab23));    background:-moz-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:-webkit-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:-o-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:-ms-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:linear-gradient(to bottom, #ffec64 5%, #ffab23 100%);    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffec64', endColorstr='#ffab23',GradientType=0);    background-color:#ffec64;    -moz-border-radius:6px;    -webkit-border-radius:6px;    border-radius:6px;    border:1px solid #ffaa22;    display:inline-block;    cursor:pointer;    color:#333333;    font-family:Arial;    font-size:15px;    font-weight:bold;    padding:6px 24px;    text-decoration:none;    text-shadow:0px 1px 0px #ffee66;z-index:9999999999999999999;margin-top:10px;}";
 
 var cssStyle = document.createElement("style");
 cssStyle.type = "text/css";
 cssStyle.id = className;
 cssStyle.appendChild(document.createTextNode(noImageCSS));
 document.documentElement.appendChild(cssStyle);
 
 var divSupported = document.createElement("div");
 
 divSupported.id = 'divSupported';
 var myDomain = window.location.href;
 //var myText = "Gutscheine verfügbar: " +myDomain;
 var myText = "Gutscheine verfügbar: ";
 divSupported.appendChild(document.createTextNode(myText));
 document.documentElement.appendChild(divSupported);
 
 //divSupported.appendChild(document.createTextNode("Gutscheine verfügbar!"));
 var divSupportedButton = document.createElement("button");
 var robinsText ="Robins holen";
 divSupportedButton.id = 'buttonSupported';
 divSupportedButton.appendChild(document.createTextNode(robinsText));
 document.documentElement.appendChild(divSupportedButton);
 divSupported.appendChild(document.createElement("br"));
 divSupported.appendChild(divSupportedButton);
 */

Object.defineProperty(window.__firefox__, "NoImageMode", {
                      enumerable: false,
                      configurable: false,
                      writable: false,
                      value: { enabled: false }
                      });

const className = "__firefox__NoImageMode";

function initializeStyleSheet () {
    var noImageCSS = "*{background-image:none !important;}img,iframe{visibility:hidden !important;}body{background-color:#440000;} #divSupported{position:fixed;top:0px;width:100%;background-color:#000;color:#fff;text-align:center;size:25px;height:90px;z-index:9999999999;padding:10px;}#buttonSupported{-moz-box-shadow: 0px 1px 0px 0px #fff6af;    -webkit-box-shadow: 0px 1px 0px 0px #fff6af;    box-shadow: 0px 1px 0px 0px #fff6af;    background:-webkit-gradient(linear, left top, left bottom, color-stop(0.05, #ffec64), color-stop(1, #ffab23));    background:-moz-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:-webkit-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:-o-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:-ms-linear-gradient(top, #ffec64 5%, #ffab23 100%);    background:linear-gradient(to bottom, #ffec64 5%, #ffab23 100%);    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffec64', endColorstr='#ffab23',GradientType=0);    background-color:#ffec64;    -moz-border-radius:6px;    -webkit-border-radius:6px;    border-radius:6px;    border:1px solid #ffaa22;    display:inline-block;    cursor:pointer;    color:#333333;    font-family:Arial;    font-size:15px;    font-weight:bold;    padding:6px 24px;    text-decoration:none;    text-shadow:0px 1px 0px #ffee66;z-index:9999999999999999999;margin-top:10px;}";
    var newCss = document.getElementById(className);
    if (!newCss) {
        var cssStyle = document.createElement("style");
        cssStyle.type = "text/css";
        cssStyle.id = className;
        cssStyle.appendChild(document.createTextNode(noImageCSS));
        document.documentElement.appendChild(cssStyle);
        
        var divSupported = document.createElement("div");
        
        divSupported.id = 'divSupported';
        var myDomain = window.location.href;
        //var myText = "Gutscheine verfügbar: " +myDomain;
        var myText = "Gutscheine verfügbar: ";
        divSupported.appendChild(document.createTextNode(myText));
        document.documentElement.appendChild(divSupported);
        
        //divSupported.appendChild(document.createTextNode("Gutscheine verfügbar!"));
        var divSupportedButton = document.createElement("button");
        var robinsText ="Robins holen";
        divSupportedButton.id = 'buttonSupported';
        divSupportedButton.appendChild(document.createTextNode(robinsText));
        document.documentElement.appendChild(divSupportedButton);
        divSupported.appendChild(document.createElement("br"));
        divSupported.appendChild(divSupportedButton);
        
        
    } else {
        newCss.innerHTML = noImageCSS;
    }
}

Object.defineProperty(window.__firefox__.NoImageMode, "setEnabled", {
                      enumerable: false,
                      configurable: false,
                      writable: false,
                      value: function(enabled) {
                      if (enabled === window.__firefox__.NoImageMode.enabled) {
                      return;
                      }
                      window.__firefox__.NoImageMode.enabled = enabled;
                      if (enabled) {
                      initializeStyleSheet();
                      return;
                      }
                      
                      // Disable no image mode //
                      
                      // It would be useful to also revert the changes we've made, rather than just to prevent any more images from being loaded
                      var style = document.getElementById(className);
                      if (style) {
                      style.remove();
                      }
                      
                      [].slice.apply(document.getElementsByTagName("img")).forEach(function(el) {
                                                                                   var src = el.src;
                                                                                   el.src = "";
                                                                                   el.src = src;
                                                                                   });
                      
                      [].slice.apply(document.querySelectorAll("[style*=\"background\"]")).forEach(function(el) {
                                                                                                   var backgroundImage = el.style.backgroundImage;
                                                                                                   el.style.backgroundImage = "none";
                                                                                                   el.style.backgroundImage = backgroundImage;
                                                                                                   });
                      
                      [].slice.apply(document.styleSheets).forEach(function(styleSheet) {
                                                                   [].slice.apply(styleSheet.rules || []).forEach(function(rules) {
                                                                                                                  var style = rules.style;
                                                                                                                  if (!style) {
                                                                                                                  return;
                                                                                                                  }
                                                                                                                  
                                                                                                                  var backgroundImage = style.backgroundImage;
                                                                                                                  style.backgroundImage = "none";
                                                                                                                  style.backgroundImage = backgroundImage;
                                                                                                                  });
                                                                   });
                      }
                      });

window.addEventListener("DOMContentLoaded", function (event) {
                        window.__firefox__.NoImageMode.setEnabled(window.__firefox__.NoImageMode.enabled);
                        });
