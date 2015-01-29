/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

function findImageSrcLinkAtPoint(x, y) {
    var  imageLink = {};
    e = document.elementFromPoint(x, y);
    while (e && ! e.src) {
        e = e.parentNode;
    }
    if (e && e.src) {
        imageLink["imageSrc"] = e.src
    }
    return imageLink;
}

function findHrefLinkAtPoint(x, y) {
    var  hrefLink = {};
    e = document.elementFromPoint(x, y);
    while (e && ! e.href) {
        e = e.parentNode;
    }
    if (e && e.href) {
        hrefLink["hrefLink"] = e.href
    }
    return hrefLink;
}

function findElementsAtPoint(x, y) {
    var jsonResult = {};
    jsonResult["hrefElement"] = findHrefLinkAtPoint(x, y);
    jsonResult["imageElement"] = findImageSrcLinkAtPoint(x, y);
    webkit.messageHandlers.longPressMessageHandler.postMessage(jsonResult);
}
