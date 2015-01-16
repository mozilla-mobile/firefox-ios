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
protocol ReaderModeDelegate {
    func readerMode(readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forBrowser browser: Browser)
}

class ReaderMode: BrowserHelper {
    var delegate: ReaderModeDelegate?

    private weak var browser: Browser?
    var state: ReaderModeState = ReaderModeState.Unavailable
    private var originalURL: NSURL?

    class func name() -> String {
        return "ReaderMode"
    }

    required init?(browser: Browser) {
        self.browser = browser

        // This is a WKUserScript at the moment because webView.evaluateJavaScript() fails with an unspecified error. Possibly script size related.
        if let path = NSBundle.mainBundle().pathForResource("Readability", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView.configuration.userContentController.addUserScript(userScript)
            }
        }

        // This is executed after a page has been loaded. It executes Readability and then fires a script message to let us know if the page is compatible with reader mode.
        if let path = NSBundle.mainBundle().pathForResource("ReaderMode", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "readerModeMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        println("DEBUG: readerModeMessageHandler message: \(message.body)")
        if let state = ReaderModeState(rawValue: message.body as String) {
            self.state = state
            delegate?.readerMode(self, didChangeReaderModeState: state, forBrowser: browser!)
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
        if state == ReaderModeState.Available {
            browser!.webView.evaluateJavaScript("mozReaderize()", completionHandler: { (object, error) -> Void in
                println("DEBUG: mozReaderize object=\(object != nil) error=\(error)")
                if error == nil {
                    self.state = ReaderModeState.Active
                    self.originalURL = self.browser!.webView.URL
                    self.browser!.webView.loadHTMLString(object as String, baseURL: self.constructAboutReaderURL(self.browser!.webView.URL))
                } else {
                    // TODO What do we do in case of errors? At this point we actually did show the button, so the user does expect some feedback I think.
                }
            })
        }
    }

    func disableReaderMode() {
        if state == ReaderModeState.Active {
            state = ReaderModeState.Available
            self.browser!.webView.loadRequest(NSURLRequest(URL: originalURL!))
            originalURL = nil
        }
    }

    func toggleReaderMode() {
        if state == ReaderModeState.Active {
            disableReaderMode()
        } else {
            enableReaderMode()
        }
    }
}