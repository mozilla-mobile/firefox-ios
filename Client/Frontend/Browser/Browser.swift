/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

enum ReaderModeState: String {
    case Available = "Available"
    case Unavailable = "Unavailable"
    case Active = "Active"
}

/// Delegate that contains callbacks that we have added on top of the built-in WKWebViewDelegate
protocol BrowserDelegate {
    func browser(browser: Browser, didChangeReaderModeState state: ReaderModeState)
}

class Browser: NSObject, WKScriptMessageHandler {
    let webView = WKWebView(frame: CGRectZero, configuration: WKWebViewConfiguration())
    var delegate: BrowserDelegate?

    override init() {
        super.init()
        
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.userContentController = WKUserContentController()

        // This is a WKUserScript at the moment because webView.evaluateJavaScript() fails with an unspecified error. Possibly script size related.
        if let path = NSBundle.mainBundle().pathForResource("Readability", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                webView.configuration.userContentController.addUserScript(userScript)
            }
        }
        
        // This is executed after a page has been loaded. It executes Readability and then fires a script message to let us know if the page is compatible with reader mode.
        if let path = NSBundle.mainBundle().pathForResource("ReaderMode", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                webView.configuration.userContentController.addUserScript(userScript)
                webView.configuration.userContentController.addScriptMessageHandler(self, name: "readerModeMessageHandler")
            }
        }
    }

    var backList: [WKBackForwardListItem]? {
        return webView.backForwardList.backList as? [WKBackForwardListItem]
    }

    var forwardList: [WKBackForwardListItem]? {
        return webView.backForwardList.forwardList as? [WKBackForwardListItem]
    }

    var url: NSURL? {
        return webView.URL?
    }

    var canGoBack: Bool {
        return webView.canGoBack
    }

    var canGoForward: Bool {
        return webView.canGoForward
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func goToBackForwardListItem(item: WKBackForwardListItem) {
        webView.goToBackForwardListItem(item)
    }

    func loadRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }

    // This lives here because it is tightly coupled to the WKWebView and the WKUserScript requires
    // a target to dispatch messages to. That target can only be set when the userscripts are
    // created initially and cannot be swapped in/out on tab change so they cannot be handled by the
    // BrowserViewController.

    var readerModeState: ReaderModeState = ReaderModeState.Unavailable
    var readerModeOriginalURL: NSURL?

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if message.name == "readerModeMessageHandler" {
            println("DEBUG: readerModeMessageHandler message: \(message.body)")
            if let state = ReaderModeState(rawValue: message.body as String) {
                readerModeState = state
                delegate?.browser(self, didChangeReaderModeState: readerModeState)
            }
        }
    }

    private func constructAboutReaderURL(originalURL: NSURL?) -> NSURL {
        if let url = originalURL?.absoluteString {
            if let encoded = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) {
                if let aboutReaderURL = NSURL(string: "about:reader?url=\(encoded)") {
                    return aboutReaderURL
                }
            }
        }
        return NSURL(string: "about:reader")!
    }
    
    func enableReaderMode() {
        if readerModeState == ReaderModeState.Available {
            webView.evaluateJavaScript("mozReaderize()", completionHandler: { (object, error) -> Void in
                println("DEBUG: mozReaderize object=\(object != nil) error=\(error)")
                if error == nil {
                    self.readerModeState = ReaderModeState.Active
                    self.readerModeOriginalURL = self.webView.URL
                    self.webView.loadHTMLString(object as String, baseURL: self.constructAboutReaderURL(self.webView.URL))
                } else {
                    // TODO What do we do in case of errors? At this point we actually did show the button, so the user does expect some feedback I think.
                }
            })
        }
    }
    
    func disableReaderMode() {
        if readerModeState == ReaderModeState.Active {
            readerModeState = ReaderModeState.Available
            webView.loadRequest(NSURLRequest(URL: readerModeOriginalURL!))
            readerModeOriginalURL = nil
        }
    }

    func toggleReaderMode() {
        if readerModeState == ReaderModeState.Active {
            disableReaderMode()
        } else {
            enableReaderMode()
        }
    }
}
