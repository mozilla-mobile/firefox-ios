/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers

struct ReaderModeHandlers {
    static var readerModeCache: ReaderModeCache = DiskReaderModeCache.sharedInstance

    static func register(webServer: WebServer, profile: Profile) {
        // Register our fonts and css, which we want to expose to web content that we present in the WebView
        webServer.registerMainBundleResourcesOfType("ttf", module: "reader-mode/fonts")
        webServer.registerMainBundleResource("Reader.css", module: "reader-mode/styles")

        // Register a handler that simply lets us know if a document is in the cache or not. This is called from the
        // reader view interstitial page to find out when it can stop showing the 'Loading...' page and instead load
        // the readerized content.
        webServer.registerHandlerForMethod("GET", module: "reader-mode", resource: "page-exists") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            guard let stringURL = request.query["url"] as? String,
                  let url = NSURL(string: stringURL) else {
                return GCDWebServerResponse(statusCode: 500)
            }

            let status = readerModeCache.contains(url) ? 200 : 404
            return GCDWebServerResponse(statusCode: status)
        }

        // Register the handler that accepts /reader-mode/page?url=http://www.example.com requests.
        webServer.registerHandlerForMethod("GET", module: "reader-mode", resource: "page") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            if let url = request.query["url"] as? String {
                if let url = NSURL(string: url) where url.isWebPage() {
                    do {
                        let readabilityResult = try readerModeCache.get(url)
                        // We have this page in our cache, so we can display it. Just grab the correct style from the
                        // profile and then generate HTML from the Readability results.
                        var readerModeStyle = DefaultReaderModeStyle
                        if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
                            if let style = ReaderModeStyle(dict: dict) {
                                readerModeStyle = style
                            }
                        }
                        if let html = ReaderModeUtils.generateReaderContent(readabilityResult, initialStyle: readerModeStyle) {
                            let response = GCDWebServerDataResponse(HTML: html)
                            // Apply a Content Security Policy that disallows everything except images from anywhere and fonts and css from our internal server
//                            response.setValue("default-src 'none'; img-src *; style-src http://localhost:*; font-src http://localhost:*", forAdditionalHeader: "Content-Security-Policy")
                            return response
                        }
                    } catch _ {
                        // This page has not been converted to reader mode yet. This happens when you for example add an
                        // item via the app extension and the application has not yet had a change to readerize that
                        // page in the background.
                        //
                        // What we do is simply queue the page in the ReadabilityService and then show our loading
                        // screen, which will periodically call page-exists to see if the readerized content has
                        // become available.
                        ReadabilityService.sharedInstance.process(url, cache: readerModeCache)
                        if let readerViewLoadingPath = NSBundle.mainBundle().pathForResource("ReaderViewLoading", ofType: "html") {
                            do {
                                let readerViewLoading = try NSMutableString(contentsOfFile: readerViewLoadingPath, encoding: NSUTF8StringEncoding)
                                readerViewLoading.replaceOccurrencesOfString("%ORIGINAL-URL%", withString: url.absoluteString,
                                    options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, readerViewLoading.length))
                                readerViewLoading.replaceOccurrencesOfString("%LOADING-TEXT%", withString: NSLocalizedString("Loading content…", comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Firefox reader mode from another app."),
                                    options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, readerViewLoading.length))
                                readerViewLoading.replaceOccurrencesOfString("%LOADING-FAILED-TEXT%", withString: NSLocalizedString("The page could not be displayed in Reader View.", comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Firefox reader mode from another app."),
                                    options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, readerViewLoading.length))
                                readerViewLoading.replaceOccurrencesOfString("%LOAD-ORIGINAL-TEXT%", withString: NSLocalizedString("Load original page", comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Firefox reader mode from another app."),
                                    options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, readerViewLoading.length))
                                return GCDWebServerDataResponse(HTML: readerViewLoading as String)
                            } catch _ {
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