// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Common

enum WebAgentError: Error {
    case invalidResult
    case decodingFailed(Error)
    case jsEvaluationFailed(Error)
}

final class WebAgentPerception {
    private let maxAttempts: Int
    private let logger: Logger

    init(maxAttempts: Int = 4, logger: Logger = DefaultLogger.shared) {
        self.maxAttempts = maxAttempts
        self.logger = logger
    }

    @MainActor
    func extract(on webView: WKWebView) async throws -> AgentPageMap {
        let jsCall = "return await window.__firefox__.WebAgent.extractPage()"
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            do {
                let raw = try await webView.callAsyncJavaScript(jsCall, contentWorld: .defaultClient)
                guard let raw, JSONSerialization.isValidJSONObject(raw) else {
                    lastError = WebAgentError.invalidResult
                    continue
                }
                let data = try JSONSerialization.data(withJSONObject: raw)
                let map = try JSONDecoder().decode(AgentPageMap.self, from: data)
                // A valid-but-empty map usually means the page hasn't rendered
                // its content yet (slow load / client-side render). Retry rather
                // than feed the model a blank page.
                if map.summary.total == 0 && attempt < maxAttempts - 1 {
                    lastError = WebAgentError.invalidResult
                    continue
                }
                return map
            } catch let error as DecodingError {
                logger.log("WebAgent perception decode failed", level: .warning, category: .webview)
                throw WebAgentError.decodingFailed(error)
            } catch {
                lastError = WebAgentError.jsEvaluationFailed(error)
            }
        }

        logger.log("WebAgent perception failed after retries", level: .warning, category: .webview)
        throw lastError ?? WebAgentError.invalidResult
    }
}
