// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Unified interface for all summary backends.
/// All implementations ( local models, litellm, ... ) must conform to this.
protocol SummarizerProtocol {
    func summarize(prompt: String, text: String) async throws -> String
    /// TODO(FXIOS-12931): Follow-up use AsyncStream and drop `onChunk` callback for better DX.
    func summarizeStreamed(prompt: String, text: String, onChunk: @escaping @Sendable (String) -> Void) async throws
}
