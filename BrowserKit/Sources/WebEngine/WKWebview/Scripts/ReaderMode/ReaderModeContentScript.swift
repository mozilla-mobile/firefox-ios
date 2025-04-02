// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public enum ReaderModeInfo: String {
    case namespace = "window.__firefox__.reader"
}

protocol ReaderModeStyleSetter {
    var style: ReaderModeStyle { get set }
}

class ReaderModeContentScript: WKContentScript, ReaderModeStyleSetter {
    // TODO: FXIOS-11373 - This delegate needs to be set
    weak var delegate: WKReaderModeDelegate?

    private var logger: Logger
    fileprivate weak var session: WKEngineSession?
    var state = ReaderModeState.unavailable
    fileprivate var originalURL: URL?

    class func name() -> String {
        return "ReaderMode"
    }

    required init(session: WKEngineSession,
                  logger: Logger = DefaultLogger.shared) {
        self.session = session
        self.logger = logger
    }

    func scriptMessageHandlerNames() -> [String] {
        return ["readerModeMessageHandler"]
    }

    private func handleReaderPageEvent(_ readerPageEvent: ReaderPageEvent) {
        switch readerPageEvent {
        case .pageShow:
            guard let session else { return }
            delegate?.readerMode(self, didDisplayReaderizedContentForSession: session)
        }
    }

    private func handleReaderModeStateChange(_ state: ReaderModeState) {
        self.state = state
        guard let session else { return }
        delegate?.readerMode(self, didChangeReaderModeState: state, forSession: session)
    }

    private func handleReaderContentParsed(_ readabilityResult: ReadabilityResult) {
        guard let session else { return }
        logger.log("Reader content parsed",
                   level: .debug,
                   category: .library)
        session.sessionData.readabilityResult = readabilityResult
        delegate?.readerMode(self, didParseReadabilityResult: readabilityResult, forSession: session)
    }

    func userContentController(didReceiveMessage message: Any) {
        guard let body = message as? [String: Any],
              let type = body["Type"] as? String,
              let messageType = ReaderModeMessageType(rawValue: type)
        else { return }

        switch messageType {
        case .pageEvent:
            if let readerPageEvent = ReaderPageEvent(rawValue: body["Value"] as? String ?? "Invalid") {
                handleReaderPageEvent(readerPageEvent)
            }
        case .stateChange:
            if let readerModeState = ReaderModeState(rawValue: body["Value"] as? String ?? "Invalid") {
                handleReaderModeStateChange(readerModeState)
            }
        case .contentParsed:
            if let readabilityResult = ReadabilityResult(object: body["Value"] as AnyObject?) {
                handleReaderContentParsed(readabilityResult)
            }
        }
    }

    // This sets the style onto the reader mode through JavaScript injection
    lazy var style = ReaderModeStyle.defaultStyle() {
        didSet {
            if state == ReaderModeState.active, let session {
                session.setReaderMode(style: style, namespace: ReaderModeInfo.namespace)
            }
        }
    }
}
