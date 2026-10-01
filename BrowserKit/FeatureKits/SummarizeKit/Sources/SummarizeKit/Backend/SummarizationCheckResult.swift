// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Model for the JS `checkSummarization()` result
/// See UserScripts/MainFrame/AtDocumentStart/Summarizer.js for more context
public struct SummarizationCheckResult: Decodable, Equatable, Sendable {
    public let canSummarize: Bool
    public let reason: SummarizationReason?
    public let wordCount: Int
    public let textContent: String?
    public let contentType: SummarizationContentType?

    public init(
        canSummarize: Bool,
        reason: SummarizationReason?,
        wordCount: Int,
        textContent: String?,
        contentType: SummarizationContentType?
    ) {
        self.canSummarize = canSummarize
        self.reason = reason
        self.wordCount = wordCount
        self.textContent = textContent
        self.contentType = contentType
    }

    /// Convenience initializer for constructing a failure result.
    public static func failure(_ error: SummarizationCheckError) -> SummarizationCheckResult {
        SummarizationCheckResult(canSummarize: false, reason: nil, wordCount: 0, textContent: nil, contentType: nil)
    }
}
