// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Unified interface for all summary backends.
/// All implementations ( local models, litellm, ... ) must conform to this.
public protocol SummarizerProtocol: Sendable {
    var modelName: SummarizerModel { get }
    func summarize(_ contentToSummarize: String) async throws -> String
    func summarizeStreamed(_ contentToSummarize: String) async throws -> AsyncThrowingStream<String, Error>
}
