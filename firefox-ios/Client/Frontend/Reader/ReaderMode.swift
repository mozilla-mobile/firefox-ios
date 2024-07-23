// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import WebKit

let ReaderModeProfileKeyStyle = "readermode.style"

enum ReaderModeMessageType: String {
    case stateChange = "ReaderModeStateChange"
    case pageEvent = "ReaderPageEvent"
    case contentParsed = "ReaderContentParsed"
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
    case light
    case dark
    case sepia

    static func preferredTheme(for theme: ReaderModeTheme? = nil, window: WindowUUID?) -> ReaderModeTheme {
        let themeManager: ThemeManager = AppContainer.shared.resolve()

        let appTheme: Theme = {
            guard let uuid = window else { return themeManager.windowNonspecificTheme() }
            return themeManager.getCurrentTheme(for: uuid)
        }()

        guard appTheme.type != .dark else { return .dark }

        return theme ?? ReaderModeTheme.light
    }
}

private struct FontFamily {
    static let serifFamily = [ReaderModeFontType.serif, ReaderModeFontType.serifBold]
    static let sansFamily = [ReaderModeFontType.sansSerif, ReaderModeFontType.sansSerifBold]
    static let families = [serifFamily, sansFamily]
}

enum ReaderModeFontType: String {
    case serif = "serif"
    case serifBold = "serif-bold"
    case sansSerif = "sans-serif"
    case sansSerifBold = "sans-serif-bold"

    init(type: String) {
        let font = ReaderModeFontType(rawValue: type)
        let isBoldFontEnabled = UIAccessibility.isBoldTextEnabled

        switch font {
        case .serif,
                .serifBold:
            self = isBoldFontEnabled ? .serifBold : .serif
        case .sansSerif,
                .sansSerifBold:
            self = isBoldFontEnabled ? .sansSerifBold : .sansSerif
        case .none:
            self = .sansSerif
        }
    }

    func isSameFamily(_ font: ReaderModeFontType) -> Bool {
        return FontFamily.families.contains(where: { $0.contains(font) && $0.contains(self) })
    }
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
            return .size2
        case .medium:
            return .size3
        case .large:
            return .size5
        case .extraLarge:
            return .size7
        case .extraExtraLarge:
            return .size9
        case .extraExtraExtraLarge:
            return .size12
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
    let windowUUID: WindowUUID?
    var theme: ReaderModeTheme
    var fontType: ReaderModeFontType
    var fontSize: ReaderModeFontSize

    /// Encode the style to a JSON dictionary that can be passed to ReaderMode.js
    func encode() -> String {
        return encodeAsDictionary().asString ?? ""
    }

    /// Encode the style to a dictionary that can be stored in the profile
    func encodeAsDictionary() -> [String: Any] {
        return ["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]
    }

    init(windowUUID: WindowUUID?,
         theme: ReaderModeTheme,
         fontType: ReaderModeFontType,
         fontSize: ReaderModeFontSize) {
        self.windowUUID = windowUUID
        self.theme = theme
        self.fontType = fontType
        self.fontSize = fontSize
    }

    /// Initialize the style from a dictionary, taken from the profile. Returns nil if the object cannot be decoded.
    init?(windowUUID: WindowUUID?, dict: [String: Any]) {
        let themeRawValue = dict["theme"] as? String
        let fontTypeRawValue = dict["fontType"] as? String
        let fontSizeRawValue = dict["fontSize"] as? Int
        if themeRawValue == nil || fontTypeRawValue == nil || fontSizeRawValue == nil {
            return nil
        }

        let theme = ReaderModeTheme(rawValue: themeRawValue!)
        let fontType = ReaderModeFontType(type: fontTypeRawValue!)
        let fontSize = ReaderModeFontSize(rawValue: fontSizeRawValue!)
        if theme == nil || fontSize == nil {
            return nil
        }

        self.windowUUID = windowUUID
        self.theme = theme ?? ReaderModeTheme.preferredTheme(window: windowUUID)
        self.fontType = fontType
        self.fontSize = fontSize!
    }

    mutating func ensurePreferredColorThemeIfNeeded() {
        self.theme = ReaderModeTheme.preferredTheme(for: self.theme, window: windowUUID)
    }

    static func defaultStyle(for window: WindowUUID? = nil) -> ReaderModeStyle {
        return ReaderModeStyle(
            windowUUID: window,
            theme: .light,
            fontType: .sansSerif,
            fontSize: ReaderModeFontSize.defaultSize
        )
    }
}

/// This struct captures the response from the Readability.js code.
struct ReadabilityResult {
    /// The `dir` global attribute is an enumerated attribute that indicates the directionality of the element's text
    enum Direction: String {
        /// Direction for languages that are written from the left to the right
        case leftToRight = "ltr"
        /// Direction for languages that are written from the right to the left
        case rightToLeft = "rtl"
        /// Direction base on the user agent algorithm, which uses a basic algorithm
        /// as it parses the characters inside the element until it finds a character
        /// with a strong directionality, then applies that directionality to the
        /// whole element
        case auto
    }
    let content: String
    let textContent: String
    let title: String
    let credits: String
    let byline: String
    let excerpt: String
    let length: Int
    let language: String
    let siteName: String
    let direction: Direction

    init?(object: AnyObject?) {
        guard let dict = object as? NSDictionary else { return nil }

        self.content = dict["content"] as? String ?? ""
        self.textContent = dict["textContent"] as? String ?? ""
        self.excerpt = dict["excerpt"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.length = dict["length"] as? Int ?? .zero
        self.language = dict["language"] as? String ?? ""
        self.siteName = dict["siteName"] as? String ?? ""
        self.credits = dict["credits"] as? String ?? ""
        self.byline = dict["byline"] as? String ?? ""
        self.direction = Direction(rawValue: dict["dir"] as? String ?? "") ?? .auto
    }

    /// Initialize from a JSON encoded string
    init?(string: String) {
        guard let data = string.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
              ) as? [String: Any],
              let content = object["content"] as? String,
              let title = object["title"] as? String,
              let credits = object["byline"] as? String
        else { return nil }

        self.content = content
        self.title = title
        self.credits = credits
        self.textContent = object["textContent"] as? String ?? ""
        self.excerpt = object["excerpt"] as? String ?? ""
        self.length = object["length"] as? Int ?? .zero
        self.language = object["language"] as? String ?? ""
        self.siteName = object["siteName"] as? String ?? ""
        self.byline = object["byline"] as? String ?? ""
        self.direction = Direction(rawValue: object["dir"] as? String ?? "") ?? .auto
    }

    /// Encode to a dictionary, which can then for example be json encoded
    func encode() -> [String: Any] {
        return [
            "content": content,
            "title": title,
            "credits": credits,
            "textContent": textContent,
            "excerpt": excerpt,
            "byline": byline,
            "length": length,
            "dir": direction.rawValue,
            "siteName": siteName,
            "lang": language
        ]
    }

    /// Encode to a JSON encoded string
    func encode() -> String {
        let dict: [String: Any] = self.encode()
        return dict.asString!
    }
}

/// Delegate that contains callbacks that we have added on top of the built-in WKWebViewDelegate
protocol ReaderModeDelegate: AnyObject {
    func readerMode(
        _ readerMode: ReaderMode,
        didChangeReaderModeState state: ReaderModeState,
        forTab tab: Tab
    )
    func readerMode(
        _ readerMode: ReaderMode,
        didDisplayReaderizedContentForTab tab: Tab
    )
    func readerMode(
        _ readerMode: ReaderMode,
        didParseReadabilityResult readabilityResult: ReadabilityResult,
        forTab tab: Tab
    )
}

let ReaderModeNamespace = "window.__firefox__.reader"

class ReaderMode: TabContentScript {
    weak var delegate: ReaderModeDelegate?

    private var logger: Logger
    fileprivate weak var tab: Tab?
    var state = ReaderModeState.unavailable
    fileprivate var originalURL: URL?

    class func name() -> String {
        return "ReaderMode"
    }

    required init(tab: Tab,
                  logger: Logger = DefaultLogger.shared) {
        self.tab = tab
        self.logger = logger
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["readerModeMessageHandler"]
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
        guard let tab = tab else { return }
        delegate?.readerMode(self, didChangeReaderModeState: state, forTab: tab)
    }

    fileprivate func handleReaderContentParsed(_ readabilityResult: ReadabilityResult) {
        guard let tab = tab else { return }
        logger.log("Reader content parsed",
                   level: .debug,
                   category: .library)
        tab.readabilityResult = readabilityResult
        delegate?.readerMode(self, didParseReadabilityResult: readabilityResult, forTab: tab)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let msg = message.body as? [String: Any],
              let type = msg["Type"] as? String,
              let messageType = ReaderModeMessageType(rawValue: type)
        else { return }

        switch messageType {
        case .pageEvent:
            if let readerPageEvent = ReaderPageEvent(rawValue: msg["Value"] as? String ?? "Invalid") {
                handleReaderPageEvent(readerPageEvent)
            }
        case .stateChange:
            if let readerModeState = ReaderModeState(rawValue: msg["Value"] as? String ?? "Invalid") {
                handleReaderModeStateChange(readerModeState)
            }
        case .contentParsed:
            if let readabilityResult = ReadabilityResult(object: msg["Value"] as AnyObject?) {
                handleReaderContentParsed(readabilityResult)
            }
        }
    }

    lazy var style = ReaderModeStyle.defaultStyle(for: tab?.windowUUID) {
        didSet {
            if state == ReaderModeState.active {
                tab?.webView?.evaluateJavascriptInDefaultContentWorld(
                        "\(ReaderModeNamespace).setStyle(\(style.encode()))"
                    ) { object, error in
                    return
                }
            }
        }
    }
}
