// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Foundation

/// Model for all the reasons summarization might be disallowed.
public enum SummarizationReason: String, Decodable {
    case documentNotReady, documentNotReadable, contentTooLong
}

/// Model for the JS `checkSummarization()` result
/// See UserScripts/MainFrame/AtDocumentStart/Summarizer.js for more context
public struct SummarizationCheckResult: Decodable {
    public let canSummarize: Bool
    public let reason: SummarizationReason?
    public let wordCount: Int

    /// Convenience initializer for constructing a failure result.
    static func failure(_ error: SummarizationCheckError) -> SummarizationCheckResult {
        SummarizationCheckResult(canSummarize: false, reason: nil, wordCount: 0)
    }
}

/// Possible errors encountered when evaluating or parsing the JS result.
public enum SummarizationCheckError: Error {
    /// Thrown when `evaluateJavaScript` itself fails.
    case jsEvaluationFailed(Error)
    /// Thrown when the raw JS result is not valid JSON.
    case invalidJSON
    /// Thrown when decoding the JSON into a model fails.
    case decodingFailed(Error)

    var description: String {
        switch self {
        case .jsEvaluationFailed(let error):
            return "JavaScript evaluation failed: \(error.localizedDescription)"
        case .invalidJSON:
            return "Invalid JSON from page script"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        }
    }
}

public struct SummarizationChecker {
    /// Calls `checkSummarization(maxWords:)` in the web page and returns a typed result.
    /// - Parameters:
    ///   - webView: The WKWebView instance with the JS already injected.
    ///   - maxWords: The maximum allowed words before summarization is disallowed.
    /// - Returns: A `SummarizationCheckResult`, even on error.
    public static func check(on webView: WKWebView, maxWords: Int) async -> SummarizationCheckResult {
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
    public static func parse(_ rawResult: Any) throws -> SummarizationCheckResult {
        guard JSONSerialization.isValidJSONObject(rawResult) else { throw SummarizationCheckError.invalidJSON }
        do {
            let data = try JSONSerialization.data(withJSONObject: rawResult)
            return try JSONDecoder().decode(SummarizationCheckResult.self, from: data)
        } catch {
            throw SummarizationCheckError.decodingFailed(error)
        }
    }
}
