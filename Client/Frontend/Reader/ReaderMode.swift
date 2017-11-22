/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit
import SwiftyJSON

let ReaderModeProfileKeyStyle = "readermode.style"

enum ReaderModeMessageType: String {
    case stateChange = "ReaderModeStateChange"
    case pageEvent = "ReaderPageEvent"
}

enum ReaderPageEvent: String {
    case pageShow = "PageShow"
}

enum ReaderModeState: String {
    case available = "Available"
    case unavailable = "Unavailable"
    case active = "Active"
}

enum ReaderModeTheme: String {
    case light = "light"
    case dark = "dark"
    case sepia = "sepia"
}

enum ReaderModeFontType: String {
    case serif = "serif"
    case sansSerif = "sans-serif"
}

enum ReaderModeFontSize: Int {
    case size1 = 1
    case size2 = 2
    case size3 = 3
    case size4 = 4
    case size5 = 5
    case size6 = 6
    case size7 = 7
    case size8 = 8
    case size9 = 9
    case size10 = 10
    case size11 = 11
    case size12 = 12
    case size13 = 13

    func isSmallest() -> Bool {
        return self == ReaderModeFontSize.size1
    }

    func smaller() -> ReaderModeFontSize {
        if isSmallest() {
            return self
        } else {
            return ReaderModeFontSize(rawValue: self.rawValue - 1)!
        }
    }

    func isLargest() -> Bool {
        return self == ReaderModeFontSize.size13
    }

    static var defaultSize: ReaderModeFontSize {
        switch UIApplication.shared.preferredContentSizeCategory {
        case .extraSmall:
            return .size1
        case .small:
            return .size3
        case .medium:
            return .size5
        case .large:
            return .size7
        case .extraLarge:
            return .size9
        case .extraExtraLarge:
            return .size11
        case .extraExtraExtraLarge:
            return .size13
        default:
            return .size5
        }
    }

    func bigger() -> ReaderModeFontSize {
        if isLargest() {
            return self
        } else {
            return ReaderModeFontSize(rawValue: self.rawValue + 1)!
        }
    }
}

struct ReaderModeStyle {
    var theme: ReaderModeTheme
    var fontType: ReaderModeFontType
    var fontSize: ReaderModeFontSize

    /// Encode the style to a JSON dictionary that can be passed to ReaderMode.js
    func encode() -> String {
        return JSON(["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]).stringValue() ?? ""
    }

    /// Encode the style to a dictionary that can be stored in the profile
    func encodeAsDictionary() -> [String: Any] {
        return ["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]
    }

    init(theme: ReaderModeTheme, fontType: ReaderModeFontType, fontSize: ReaderModeFontSize) {
        self.theme = theme
        self.fontType = fontType
        self.fontSize = fontSize
    }

    /// Initialize the style from a dictionary, taken from the profile. Returns nil if the object cannot be decoded.
    init?(dict: [String: Any]) {
        guard let themeRawValue = dict["theme"] as? String,
            let fontTypeRawValue = dict["fontType"] as? String,
            let fontSizeRawValue = dict["fontSize"] as? Int,
            let theme = ReaderModeTheme(rawValue: themeRawValue),
            let fontType = ReaderModeFontType(rawValue: fontTypeRawValue),
            let fontSize = ReaderModeFontSize(rawValue: fontSizeRawValue) else { return nil }

        self.theme = theme
        self.fontType = fontType
        self.fontSize = fontSize
    }
}

let DefaultReaderModeStyle = ReaderModeStyle(theme: .light, fontType: .sansSerif, fontSize: ReaderModeFontSize.defaultSize)

/// This struct captures the response from the Readability.js code.
struct ReadabilityResult {
    var domain = ""
    var url = ""
    var content = ""
    var title = ""
    var credits = ""

    init?(object: AnyObject?) {
        guard let dict = object as? NSDictionary else { return nil }
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
    }

    /// Initialize from a JSON encoded string
    init?(string: String) {
        let object = JSON(parseJSON: string)
        guard let domain = object["domain"].string,
            let url = object["url"].string,
            let content = object["content"].string,
            let title = object["title"].string,
            let credits = object["credits"].string else { return nil }

        self.domain = domain
        self.url = url
        self.content = content
        self.title = title
        self.credits = credits
    }

    /// Encode to a dictionary, which can then for example be json encoded
    func encode() -> [String: Any] {
        return ["domain": domain, "url": url, "content": content, "title": title, "credits": credits]
    }

    /// Encode to a JSON encoded string
    func encode() -> String {
        let dict: [String: Any] = self.encode()
        return JSON(object: dict).stringValue()!
    }
}

/// Delegate that contains callbacks that we have added on top of the built-in WKWebViewDelegate
protocol ReaderModeDelegate {
    func readerMode(_ readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forTab tab: Tab)
    func readerMode(_ readerMode: ReaderMode, didDisplayReaderizedContentForTab tab: Tab)
}

let ReaderModeNamespace = "window.__firefox__.reader"

class ReaderMode: TabHelper {
    var delegate: ReaderModeDelegate?

    fileprivate weak var tab: Tab?
    var state: ReaderModeState = ReaderModeState.unavailable
    fileprivate var originalURL: URL?

    class func name() -> String {
        return "ReaderMode"
    }

    required init(tab: Tab) {
        self.tab = tab

        // This is a WKUserScript at the moment because webView.evaluateJavaScript() fails with an unspecified error. Possibly script size related.
        if let path = Bundle.main.path(forResource: "Readability", ofType: "js"),
            let source = try? String(contentsOfFile: path, encoding: .utf8) {
            let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }

        // This is executed after a page has been loaded. It executes Readability and then fires a script message to let us know if the page is compatible with reader mode.
        if let path = Bundle.main.path(forResource: "ReaderMode", ofType: "js"),
            let source = try? String(contentsOfFile: path, encoding: .utf8) {
            let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "readerModeMessageHandler"
    }

    fileprivate func handleReaderPageEvent(_ readerPageEvent: ReaderPageEvent) {
        switch readerPageEvent {
            case .pageShow:
                if let tab = tab {
                    delegate?.readerMode(self, didDisplayReaderizedContentForTab: tab)
                }
        }
    }

    fileprivate func handleReaderModeStateChange(_ state: ReaderModeState) {
        self.state = state
        guard let tab = tab else {
            return
        }
        delegate?.readerMode(self, didChangeReaderModeState: state, forTab: tab)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let msg = message.body as? Dictionary<String, String>,
            let messageType = ReaderModeMessageType(rawValue: msg["Type"] ?? "") else { return }

        switch messageType {
        case .pageEvent:
            if let readerPageEvent = ReaderPageEvent(rawValue: msg["Value"] ?? "Invalid") {
                handleReaderPageEvent(readerPageEvent)
            }
        case .stateChange:
            if let readerModeState = ReaderModeState(rawValue: msg["Value"] ?? "Invalid") {
                handleReaderModeStateChange(readerModeState)
            }
        }
    }

    var style: ReaderModeStyle = DefaultReaderModeStyle {
        didSet {
            guard state == ReaderModeState.active else { return }
            tab?.webView?.evaluateJavaScript("\(ReaderModeNamespace).setStyle(\(style.encode()))", completionHandler: { (object, error) -> Void in
                return
            })
        }
    }
}
