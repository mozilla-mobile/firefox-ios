/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

if (!this.__firefox__) {
    __firefox__ = {};
}

__firefox__.LongPress = {
    findImageSrcLinkAtPoint: function (x, y) {
        var imageLink = {};
        e = document.elementFromPoint(x, y);
        while (e && ! e.src) {
            e = e.parentNode;
        }
        if (e && e.src) {
            imageLink["imageSrc"] = e.src;
        }
        return imageLink;
    },

    findHrefLinkAtPoint: function (x, y) {
        var hrefLink = {};
        e = document.elementFromPoint(x, y);
        while (e && ! e.href) {
            e = e.parentNode;
        }
        if (e && e.href) {
            hrefLink["hrefLink"] = e.href;
        }
        return hrefLink;
    },

    findElementsAtPoint: function (x, y) {
        var jsonResult = {};
        jsonResult["hrefElement"] = this.findHrefLinkAtPoint(x, y);
        jsonResult["imageElement"] = this.findImageSrcLinkAtPoint(x, y);
        return jsonResult;
    },
};
