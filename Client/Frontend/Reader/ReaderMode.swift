/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit
import AVFoundation

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
    case Size1 = 1
    case Size2 = 2
    case Size3 = 3
    case Size4 = 4
    case Size5 = 5
    case Size6 = 6
    case Size7 = 7
    case Size8 = 8
    case Size9 = 9
    case Size10 = 10
    case Size11 = 11
    case Size12 = 12
    case Size13 = 13

    func isSmallest() -> Bool {
        return self == Size1
    }

    func smaller() -> ReaderModeFontSize {
        if isSmallest() {
            return self
        } else {
            return ReaderModeFontSize(rawValue: self.rawValue - 1)!
        }
    }

    func isLargest() -> Bool {
        return self == Size13
    }

    static var defaultSize: ReaderModeFontSize {
        switch UIApplication.sharedApplication().preferredContentSizeCategory {
        case UIContentSizeCategoryExtraSmall:
            return .Size1
        case UIContentSizeCategorySmall:
            return .Size3
        case UIContentSizeCategoryMedium:
            return .Size5
        case UIContentSizeCategoryLarge:
            return .Size7
        case UIContentSizeCategoryExtraLarge:
            return .Size9
        case UIContentSizeCategoryExtraExtraLarge:
            return .Size11
        case UIContentSizeCategoryExtraExtraExtraLarge:
            return .Size13
        default:
            return .Size5
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
        return JSON(["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]).toString(false)
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

let DefaultReaderModeStyle = ReaderModeStyle(theme: .Light, fontType: .SansSerif, fontSize: ReaderModeFontSize.defaultSize)

/// This struct captures the response from the Readability.js code.
struct ReadabilityResult {
    var domain = ""
    var url = ""
    var content = ""
    var title = ""
    var credits = ""
    var language = ""

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
            if let language = dict["language"] as? String {
                self.language = language
            }
        } else {
            return nil
        }
    }

    /// Initialize from a JSON encoded string
    init?(string: String) {
        let object = JSON(string: string)
        let domain = object["domain"].asString
        let url = object["url"].asString
        let content = object["content"].asString
        let title = object["title"].asString
        let credits = object["credits"].asString
        let language = object["language"].asString

        if domain == nil || url == nil || content == nil || title == nil || credits == nil || language == nil {
            return nil
        }

        self.domain = domain!
        self.url = url!
        self.content = content!
        self.title = title!
        self.credits = credits!
        self.language = language!
    }

    /// Encode to a dictionary, which can then for example be json encoded
    func encode() -> [String:AnyObject] {
        return ["domain": domain, "url": url, "content": content, "title": title, "credits": credits, "language": language]
    }

    /// Encode to a JSON encoded string
    func encode() -> String {
        return JSON(encode() as [String:AnyObject]).toString(false)
    }
}

/// Delegate that contains callbacks that we have added on top of the built-in WKWebViewDelegate
protocol ReaderModeDelegate {
    func readerMode(readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forTab tab: Tab)
    func readerMode(readerMode: ReaderMode, didDisplayReaderizedContentForTab tab: Tab)
    func readerMode(readerMode: ReaderMode, dictationStateDidChange state: DictationState)
}

let ReaderModeNamespace = "_firefox_ReaderMode"

class ReaderMode: TabHelper, ReaderModeDictationDelegate {
    var delegate: ReaderModeDelegate?

    private weak var tab: Tab?
    var state: ReaderModeState = ReaderModeState.Unavailable
    private var originalURL: NSURL?
    
    private var dictation = ReaderModeDictation()

    class func name() -> String {
        return "ReaderMode"
    }

    required init(tab: Tab) {
        self.tab = tab

        self.dictation.delegate = self

        // This is a WKUserScript at the moment because webView.evaluateJavaScript() fails with an unspecified error. Possibly script size related.
        if let path = NSBundle.mainBundle().pathForResource("Readability", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                tab.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }

        // This is executed after a page has been loaded. It executes Readability and then fires a script message to let us know if the page is compatible with reader mode.
        if let path = NSBundle.mainBundle().pathForResource("ReaderMode", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                tab.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "readerModeMessageHandler"
    }

    private func handleReaderPageEvent(readerPageEvent: ReaderPageEvent) {
        switch readerPageEvent {
            case .PageShow:
                if let tab = tab {
                    delegate?.readerMode(self, didDisplayReaderizedContentForTab: tab)
                    if let webView = self.tab?.webView {
                        dictation.parseWebView(webView)
                    }
                }
        }
    }

    private func handleReaderModeStateChange(state: ReaderModeState) {
        self.state = state
        delegate?.readerMode(self, didChangeReaderModeState: state, forTab: tab!)
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
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

    var style: ReaderModeStyle = DefaultReaderModeStyle {
        didSet {
            if state == ReaderModeState.Active {
                tab!.webView?.evaluateJavaScript("\(ReaderModeNamespace).setStyle(\(style.encode()))", completionHandler: {
                    (object, error) -> Void in
                    return
                })
            }
        }
    }

    func readerModeDictation(readerModeDictation: ReaderModeDictation, stateDidChange state: DictationState) {
        self.delegate?.readerMode(self, dictationStateDidChange: state)
    }
    
    var isDictating: Bool {
        return dictation.state == .Playing
    }
    
    func resumeDictation() {
        switch dictation.state {
            case .Unstarted, .Finished:
                dictation.start()
            case .Paused:
                dictation.resume()
            case .Playing:
                break
        }
    }
    
    func pauseDictation() {
        if self.isDictating {
            dictation.pause()
        }
    }
    
    func endDictation() {
        dictation.end()
    }
}

enum DictationState {
    case Unstarted
    case Playing
    case Paused
    case Finished
}

protocol ReaderModeDictationDelegate: class {
    func readerModeDictation(readerModeDictation: ReaderModeDictation, stateDidChange state: DictationState)
}

class ReaderModeDictation: NSObject, AVSpeechSynthesizerDelegate {
    var state: DictationState = .Unstarted {
        didSet {
            self.delegate?.readerModeDictation(self, stateDidChange: self.state)
        }
    }

    weak var delegate: ReaderModeDictationDelegate?

    private let synthesiser = AVSpeechSynthesizer()

    private var webView: WKWebView?
    private var scrollObservers: [String: NSObjectProtocol] = [:]
    private var scrollsToFollowDictation = true
    private var contentText: String?
    private var locale: String?
    
    // We need this to deal with a bug with only one AVSpeechSynthesizer being able to be running/paused at one time
    private var cutoffPoint: Int?
    
    override init() {
        super.init()
        self.synthesiser.delegate = self
    }
    
    deinit {
        if let webView = self.webView {
            for (notification, observer) in self.scrollObservers {
                NSNotificationCenter.defaultCenter().removeObserver(observer, name: notification, object: webView.scrollView)
            }
        }
    }
    
    func parseWebView(webView: WKWebView) {
        self.webView = webView
        webView.evaluateJavaScript("document.documentElement.lang") { result, _ in
            if let locale = result as? String where !locale.isEmpty {
                self.locale = locale
            }
        }
        for notification in ([TabScrollingController.Notifications.TabBeginScrollNotification, TabScrollingController.Notifications.TabBeginZoomNotification].map { $0.rawValue }) {
            scrollObservers[notification] = NSNotificationCenter.defaultCenter().addObserverForName(notification, object: webView.scrollView, queue: nil) { [unowned self] _ in
                self.scrollsToFollowDictation = false
                webView.evaluateJavaScript("\(ReaderModeNamespace).dictation.setScrollToDictationOn(false)", completionHandler: nil)
            }
        }
        webView.evaluateJavaScript("\(ReaderModeNamespace).dictation.extractContentText()") { (result, _) in
            self.contentText = result as? String
        }
    }
    
    private func speakUtterance(string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: self.locale ?? NSBundle.mainBundle().accessibilityLanguage ?? NSLocale.preferredLanguages().first ?? "en-GB")
        self.synthesiser.speakUtterance(utterance)
    }
    
    func start() {
        guard let contentText = self.contentText else {
            return
        }
        self.state = .Playing
        self.scrollsToFollowDictation = true
        self.speakUtterance(contentText)
    }
    
    func resume() {
        self.state = .Playing
        self.scrollsToFollowDictation = true
        if let webView = self.webView {
            webView.evaluateJavaScript("\(ReaderModeNamespace).dictation.setScrollToDictationOn(true)", completionHandler: nil)
        }
        guard let contentText = self.contentText, cutoffPoint = cutoffPoint else {
            return
        }
        self.speakUtterance(NSString(string: contentText).substringFromIndex(cutoffPoint))
    }
    
    func pause() {
        self.state = .Paused
        self.synthesiser.stopSpeakingAtBoundary(.Immediate)
    }

    func end() {
        self.state = .Finished
        self.synthesiser.stopSpeakingAtBoundary(.Immediate)
        webView?.evaluateJavaScript("\(ReaderModeNamespace).dictation.unmarkAllContent()", completionHandler: nil)
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        guard let webView = self.webView, contentText = self.contentText else {
            return
        }
        if let range = characterRange.toRange() {
            let offset = contentText.characters.count - utterance.speechString.characters.count
            self.cutoffPoint = characterRange.location + offset
            webView.evaluateJavaScript("\(ReaderModeNamespace).dictation.markDictatedContent(\(range.startIndex + offset), \(range.endIndex + offset), \(self.scrollsToFollowDictation))", completionHandler: nil)
        }
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        self.end()
    }
}