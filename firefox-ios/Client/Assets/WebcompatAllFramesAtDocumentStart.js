/*
 * ATTENTION: The "eval" devtool has been used (maybe by default in mode: "development").
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
/******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "./firefox-ios/Client/Frontend/UserContent/UserScripts/AllFrames/WebcompatAtDocumentStart/FullscreenHelper.js":
/*!********************************************************************************************************************!*\
  !*** ./firefox-ios/Client/Frontend/UserContent/UserScripts/AllFrames/WebcompatAtDocumentStart/FullscreenHelper.js ***!
  \********************************************************************************************************************/
/***/ (() => {

eval("// This Source Code Form is subject to the terms of the Mozilla Public\n// License, v. 2.0. If a copy of the MPL was not distributed with this\n// file, You can obtain one at http://mozilla.org/MPL/2.0/\n\nvar isFullScreenEnabled = document.fullscreenEnabled ||\n                                    document.webkitFullscreenEnabled ||\n                                    document.mozFullScreenEnabled ||\n                                    document.msFullscreenEnabled ? true : false;\n\nvar isFullscreenVideosSupported = HTMLVideoElement.prototype.webkitEnterFullscreen !== undefined;\n\nif (!isFullScreenEnabled && isFullscreenVideosSupported && !/mobile/i.test(navigator.userAgent)) {\n    \n    HTMLElement.prototype.requestFullscreen = function() {\n        if (this.webkitRequestFullscreen !== undefined) {\n            this.webkitRequestFullscreen();\n            return true;\n        }\n        \n        if (this.webkitEnterFullscreen !== undefined) {\n            this.webkitEnterFullscreen();\n            return true;\n        }\n        \n        var video = this.querySelector(\"video\")\n        if (video !== undefined) {\n            video.webkitEnterFullscreen();\n            return true;\n        }\n        return false;\n    };\n    \n    Object.defineProperty(document, 'fullscreenEnabled', {\n        get: function() {\n            return true;\n        }\n    });\n    \n    Object.defineProperty(document.documentElement, 'fullscreenEnabled', {\n        get: function() {\n            return true;\n        }\n    });\n}\n\n\n//# sourceURL=webpack://firefox-ios/./firefox-ios/Client/Frontend/UserContent/UserScripts/AllFrames/WebcompatAtDocumentStart/FullscreenHelper.js?");

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module can't be inlined because the eval devtool is used.
/******/ 	var __webpack_exports__ = {};
/******/ 	__webpack_modules__["./firefox-ios/Client/Frontend/UserContent/UserScripts/AllFrames/WebcompatAtDocumentStart/FullscreenHelper.js"]();
/******/ 	
/******/ })()
;