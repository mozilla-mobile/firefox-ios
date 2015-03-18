/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

let ReaderModeProfileKeyStyle = "readermode.style"

enum ReaderModeMessageType: String {
    case StateChange = "ReaderModeStateChange"
    case PageEvent = "ReaderPageEvent"
}

enum ReaderPageEvent: String {
    case PageShow = "PageShow"
}

enum ReaderModeState: String {
    case Available = "Available"
    case Unavailable = "Unavailable"
    case Active = "Active"
}

enum ReaderModeTheme: String {
    case Light = "light"
    case Dark = "dark"
    case Sepia = "sepia"
}

enum ReaderModeFontType: String {
    case Serif = "serif"
    case SansSerif = "sans-serif"
}

enum ReaderModeFontSize: Int {
    case Smallest = 1
    case Small
    case Normal = 3
    case Large = 4
    case Largest = 5
}

struct ReaderModeStyle {
    var theme: ReaderModeTheme
    var fontType: ReaderModeFontType
    var fontSize: ReaderModeFontSize

    /// Encode the style to a JSON dictionary that can be passed to ReaderMode.js
    func encode() -> String {
        return JSON(["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]).toString(pretty: false)
    }

    /// Encode the style to a dictionary that can be stored in the profile
    func encode() -> [String:AnyObject] {
        return ["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]
    }

    init(theme: ReaderModeTheme, fontType: ReaderModeFontType, fontSize: ReaderModeFontSize) {
        self.theme = theme
        self.fontType = fontType
        self.fontSize = fontSize
    }

    /// Initialize the style from a dictionary, taken from the profile. Returns nil if the object cannot be decoded.
    init?(dict: [String:AnyObject]) {
        let themeRawValue = dict["theme"] as? String
        let fontTypeRawValue = dict["fontType"] as? String
        let fontSizeRawValue = dict["fontSize"] as? Int
        if themeRawValue == nil || fontTypeRawValue == nil || fontSizeRawValue == nil {
            return nil
        }

        let theme = ReaderModeTheme(rawValue: themeRawValue!)
        let fontType = ReaderModeFontType(rawValue: fontTypeRawValue!)
        let fontSize = ReaderModeFontSize(rawValue: fontSizeRawValue!)
        if theme == nil || fontType == nil || fontSize == nil {
            return nil
        }

        self.theme = theme!
        self.fontType = fontType!
        self.fontSize = fontSize!
    }
}

let DefaultReaderModeStyle = ReaderModeStyle(theme: .Light, fontType: .SansSerif, fontSize: .Normal)

let domainPrefixes = ["www.", "mobile.", "m."]

private func simplifyDomain(domain: String) -> String {
    for prefix in domainPrefixes {
        if domain.hasPrefix(prefix) {
            return domain.substringFromIndex(advance(domain.startIndex, countElements(prefix)))
        }
    }
    return domain
}

/// This struct captures the response from the Readability.js code.
struct ReadabilityResult {
    var domain = ""
    var url = ""
    var content = ""
    var title = ""
    var credits = ""

    init?(object: AnyObject?) {
        if let dict = object as? NSDictionary {
            if let uri = dict["uri"] as? NSDictionary {
                if let url = uri["spec"] as? String {
                    self.url = url
                }
                if let host = uri["host"] as? String {
                    self.domain = host
                }
            }
            if let content = dict["content"] as? String {
                self.content = content
            }
            if let title = dict["title"] as? String {
                self.title = title
            }
            if let credits = dict["byline"] as? String {
                self.credits = credits
            }
        } else {
            return nil
        }
    }
}

/// Delegate that contains callbacks that we have added on top of the built-in WKWebViewDelegate
protocol ReaderModeDelegate {
    func readerMode(readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forBrowser browser: Browser)
    func readerMode(readerMode: ReaderMode, didDisplayReaderizedContentForBrowser browser: Browser)
}

private let ReaderModeNamespace = "_firefox_ReaderMode"

class ReaderMode: BrowserHelper {
    var delegate: ReaderModeDelegate?

    private weak var browser: Browser?
    var state: ReaderModeState = ReaderModeState.Unavailable
    private var originalURL: NSURL?

    var activateImmediately: Bool = false

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

    private func handleReaderPageEvent(readerPageEvent: ReaderPageEvent) {
        switch readerPageEvent {
            case .PageShow:
                delegate?.readerMode(self, didDisplayReaderizedContentForBrowser: browser!)
        }
    }

    private func handleReaderModeStateChange(state: ReaderModeState) {
        self.state = state
        delegate?.readerMode(self, didChangeReaderModeState: state, forBrowser: browser!)

        if activateImmediately && state == ReaderModeState.Available {
            enableReaderMode()
            activateImmediately = false
        }
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        println("DEBUG: readerModeMessageHandler message: \(message.body)")
        if let msg = message.body as? Dictionary<String,String> {
            if let messageType = ReaderModeMessageType(rawValue: msg["Type"] ?? "") {
                switch messageType {
                    case .PageEvent:
                        if let readerPageEvent = ReaderPageEvent(rawValue: msg["Value"] ?? "Invalid") {
                            handleReaderPageEvent(readerPageEvent)
                        }
                        break
                    case .StateChange:
                        if let readerModeState = ReaderModeState(rawValue: msg["Value"] ?? "Invalid") {
                            handleReaderModeStateChange(readerModeState)
                        }
                        break
                }
            }
        }
    }

    func enableReaderMode() {
        if state == ReaderModeState.Available {
            browser!.webView.evaluateJavaScript("\(ReaderModeNamespace).readerize()", completionHandler: { (object, error) -> Void in
                println("DEBUG: mozReaderize object=\(object != nil) error=\(error)")
                if error == nil && object != nil {
                    if let readabilityResult = ReadabilityResult(object: object) {
                        if let html = self.generateReaderContent(readabilityResult, initialStyle: self.style) {
                            self.state = ReaderModeState.Active
                            self.originalURL = self.browser!.webView.URL
                            if let readerModeURL = ReaderMode.encodeURL(self.browser!.webView.URL) {
                                self.browser!.webView.loadHTMLString(html, baseURL: readerModeURL)
                            }
                            return
                        }
                    }
                }
                // TODO What do we do in case of errors? At this point we actually did show the button, so the user does expect some feedback I think.
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
    
    var style: ReaderModeStyle = DefaultReaderModeStyle {
        didSet {
            if state == ReaderModeState.Active {
                browser!.webView.evaluateJavaScript("\(ReaderModeNamespace).setStyle(\(style.encode()))", completionHandler: {
                    (object, error) -> Void in
                    return
                })
            }
        }
    }

    private func generateReaderContent(readabilityResult: ReadabilityResult, initialStyle: ReaderModeStyle) -> String? {
        if let stylePath = NSBundle.mainBundle().pathForResource("Reader", ofType: "css") {
            if let css = NSString(contentsOfFile: stylePath, encoding: NSUTF8StringEncoding, error: nil) {
                if let tmplPath = NSBundle.mainBundle().pathForResource("Reader", ofType: "html") {
                    if let tmpl = NSMutableString(contentsOfFile: tmplPath, encoding: NSUTF8StringEncoding, error: nil) {
                        tmpl.replaceOccurrencesOfString("%READER-CSS%", withString: css,
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-STYLE%", withString: initialStyle.encode(),
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-DOMAIN%", withString: simplifyDomain(readabilityResult.domain),
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-URL%", withString: readabilityResult.url,
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-TITLE%", withString: readabilityResult.title,
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-CREDITS%", withString: readabilityResult.credits,
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-CONTENT%", withString: readabilityResult.content,
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%WEBSERVER-BASE%", withString: WebServer.sharedInstance.base,
                            options: NSStringCompareOptions.allZeros, range: NSMakeRange(0, tmpl.length))

                        return tmpl
                    }
                }
            }
        }
        return nil
    }

    class func isReaderModeURL(url: NSURL) -> Bool {
        if let absoluteString = url.absoluteString {
            return absoluteString.hasPrefix("about:reader?url=")
        }
        return false
    }

    class func decodeURL(url: NSURL) -> NSURL? {
        if let absoluteString = url.absoluteString {
            if absoluteString.hasPrefix("about:reader?url=") {
                let encodedURL = absoluteString.substringFromIndex(advance(absoluteString.startIndex, 17))
                if let decodedURL = encodedURL.stringByRemovingPercentEncoding {
                    return NSURL(string: decodedURL)
                }
            }
        }
        return nil
    }

    class func encodeURL(url: NSURL?) -> NSURL? {
        if let absoluteString = url?.absoluteString {
            if let encodedURL = absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) {
                if let aboutReaderURL = NSURL(string: "about:reader?url=\(encodedURL)") {
                    return aboutReaderURL
                }
            }
        }
        return nil
    }
}