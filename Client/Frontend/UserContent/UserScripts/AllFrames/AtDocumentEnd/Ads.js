// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

/**
 * Send
 * - current URL
 * - cookies of this page
 * - all links found in this page
 * to the native application.
 */
function sendCurrentState() {
    let message = {
        'url': document.location.href,
        'urls': getLinks(),
        'cookies': getCookies()
    };
    
    webkit.messageHandlers.adsMessageHandler.postMessage(message);
}

/**
 * Get all links in the current page.
 *
 * @return {Array<string>} containing all current links in the current page.
 */
function getLinks() {
    let urls = [];

    let anchors = document.getElementsByTagName("a");
    for (let anchor of anchors) {
        if (!anchor.href) {
            continue;
        }
        urls.push(anchor.href);
    }

    return urls;
}

/**
 * Get all cookies for the current document.
 *
 * @return {Array<{name: string, value: string}>} containing all cookies.
 */
function getCookies() {
    let cookiesList = document.cookie.split("; ");
    let result = [];

    cookiesList.forEach(cookie => {
        var [name, ...value] = cookie.split('=');
        // For that special cases where the value contains '='.
        value = value.join("=")

        result.push({
            "name" : name,
            "value" : value
        });
    });

    return result;
}

// Whenever a page is first accessed or when loaded from cache
// send all needed data about the ads provider to the app.
const events = ["pageshow", "load"];
const eventLogger = event => {
    switch (event.type) {
    case "load":
        sendCurrentState();
        break;
    case "pageshow":
        if (event.persisted) {
            sendCurrentState();
        }
        break;
    default:
        console.log('Event:', event.type);
    }
};
events.forEach(eventName =>
    window.addEventListener(eventName, eventLogger)
);
