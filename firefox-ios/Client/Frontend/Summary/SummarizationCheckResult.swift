// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
