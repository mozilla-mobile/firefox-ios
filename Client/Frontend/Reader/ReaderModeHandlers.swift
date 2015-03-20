/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReaderModeHandlers {
    static func register(webServer: WebServer) {
        // Register our fonts, which we want to expose to web content that we present in the WebView
        webServer.registerMainBundleResourcesOfType("ttf", module: "reader-mode/fonts")

        // Register the handler that accepts /reader-mode/page?url=http://www.example.com requests
        webServer.registerHandlerForMethod("GET", module: "reader-mode", resource: "page") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            if let url = request.query["url"] as? String {
                if let url = NSURL(string: url) {
                    if let readabilityResult = ReaderModeCache.sharedInstance.get(url, error: nil) {
                        var readerModeStyle = DefaultReaderModeStyle
                        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                            if let dict = appDelegate.profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
                                if let style = ReaderModeStyle(dict: dict) {
                                    readerModeStyle = style
                                }
                            }
                        }
                        if let html = ReaderModeUtils.generateReaderContent(readabilityResult, initialStyle: readerModeStyle) {
                            return GCDWebServerDataResponse(HTML: html)
                        }
                    }
                }
            }
            return GCDWebServerDataResponse(HTML: "There was an error converting the page")
        }
    }
}