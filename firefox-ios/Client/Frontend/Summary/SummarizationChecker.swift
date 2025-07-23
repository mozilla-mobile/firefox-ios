// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Foundation

public class SummarizationChecker {
    /// Calls `checkSummarization(maxWords:)` in the web page and returns a typed result.
    /// - Parameters:
    ///   - webView: The WKWebView instance with the JS already injected.
    ///   - maxWords: The maximum allowed words before summarization is disallowed.
    /// - Returns: A `SummarizationCheckResult`, even on error.
    public func check(on webView: WKWebView, maxWords: Int) async -> SummarizationCheckResult {
        let jsCall = "checkSummarization(\(maxWords));"
        do {
            let rawResult = try await webView.evaluateJavaScript(jsCall, in: nil, contentWorld: .defaultClient)
            guard let rawResult = rawResult else { return SummarizationCheckResult.failure(.invalidJSON) }
            return try parse(rawResult)
        } catch {
            return SummarizationCheckResult.failure(.jsEvaluationFailed(error))
        }
    }

    /// Parses the raw JS evaluation result into `SummarizationCheckResult`.
    public func parse(_ rawResult: Any) throws -> SummarizationCheckResult {
        guard JSONSerialization.isValidJSONObject(rawResult) else { throw SummarizationCheckError.invalidJSON }
        do {
            let data = try JSONSerialization.data(withJSONObject: rawResult)
            return try JSONDecoder().decode(SummarizationCheckResult.self, from: data)
        } catch {
            throw SummarizationCheckError.decodingFailed(error)
        }
    }
}
