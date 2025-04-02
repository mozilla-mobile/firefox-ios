// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import WebKit
import WebEngine

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
        guard let tab else { return }
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
                    "\(ReaderModeInfo.namespace.rawValue).setStyle(\(style.encode()))"
                    ) { object, error in
                    return
                }
            }
        }
    }
}
