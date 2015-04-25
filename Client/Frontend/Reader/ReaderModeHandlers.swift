/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReaderModeHandlers {
    static func register(webServer: WebServer) {
        // Register our fonts, which we want to expose to web content that we present in the WebView
        webServer.registerMainBundleResourcesOfType("ttf", module: "reader-mode/fonts")

        // Register a handler that simply lets us know if a document is in the cache or not. This is called from the
        // reader view interstitial page to find out when it can stop showing the 'Loading...' page and instead load
        // the readerized content.
        webServer.registerHandlerForMethod("GET", module: "reader-mode", resource: "page-exists") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            if let url = request.query["url"] as? String {
                if let url = NSURL(string: url) {
                    if ReaderModeCache.sharedInstance.contains(url, error: nil) {
                        return GCDWebServerResponse(statusCode: 200)
                    } else {
                        return GCDWebServerResponse(statusCode: 404)
                    }
                }
            }
            return GCDWebServerResponse(statusCode: 500)
        }

        // Register the handler that accepts /reader-mode/page?url=http://www.example.com requests.
        webServer.registerHandlerForMethod("GET", module: "reader-mode", resource: "page") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            if let url = request.query["url"] as? String {
                if let url = NSURL(string: url) {
                    if let readabilityResult = ReaderModeCache.sharedInstance.get(url, error: nil) {
                        // We have this page in our cache, so we can display it. Just grab the correct style from the
                        // profile and then generate HTML from the Readability results.
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
                    } else {
                        // This page has not been converted to reader mode yet. This happens when you for example add an
                        // item via the app extension and the application has not yet had a change to readerize that
                        // page in the background.
                        //
                        // What we do is simply queue the page in the ReadabilityService and then show our loading
                        // screen, which will periodically call page-exists to see if the readerized content has
                        // become available.
                        ReadabilityService.sharedInstance.process(url)
                        if let readerViewLoadingPath = NSBundle.mainBundle().pathForResource("ReaderViewLoading", ofType: "html") {
                            if let readerViewLoading = NSMutableString(contentsOfFile: readerViewLoadingPath, encoding: NSUTF8StringEncoding, error: nil) {
                                return GCDWebServerDataResponse(HTML: readerViewLoading as String)
                            }
                        }
                    }
                }
            }

            let errorString = NSLocalizedString("There was an error converting the page", comment: "Error displayed when reader mode cannot be enabled")
            return GCDWebServerDataResponse(HTML: errorString) // TODO Needs a proper error page
        }
    }
}