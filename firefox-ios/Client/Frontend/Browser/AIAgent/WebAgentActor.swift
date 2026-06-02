// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Common

final class WebAgentActor {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    @MainActor
    @discardableResult
    func execute(_ decision: AgentDecision, on webView: WKWebView) async throws -> String {
        switch decision.action {
        case "navigate":
            return "navigate handled by caller"

        case "scroll":
            let dir = decision.text == "up" ? "up" : "down"
            let js = "return await window.__firefox__.WebAgent.doAction(0, 'scroll', '\(dir)')"
            let res = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
            return res as? String ?? "scrolled"

        case "click", "type", "select":
            guard let index = decision.index else { return "\(decision.action): no index" }
            let safeText = (decision.text ?? "")
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let js = "return await window.__firefox__.WebAgent.doAction(\(index), '\(decision.action)', \"\(safeText)\")"
            let res = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
            return "\(decision.action) [\(index)] -> \(res as? String ?? "?")"

        case "typeSubmit":
            guard let index = decision.index else { return "typeSubmit: no index" }
            let safeText = (decision.text ?? "")
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let js = "return await window.__firefox__.WebAgent.doAction(\(index), 'typeSubmit', \"\(safeText)\")"
            let res = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
            return "typeSubmit [\(index)] -> \(res as? String ?? "?")"

        case "done":
            return "done: \(decision.answer ?? "")"

        default:
            logger.log("WebAgent unknown action", level: .warning, category: .webview)
            return "unknown action: \(decision.action)"
        }
    }
}
