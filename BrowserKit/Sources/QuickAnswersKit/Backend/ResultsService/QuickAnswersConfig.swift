// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit

/// A configuration container for the quick answers results feature.
public struct QuickAnswersConfig: LLMConfig, Sendable {
    public let instructions: String
    // FIXME: FXIOS-13417 We should strongly type options in the future so they can be any Sendable & Hashable
    // See `SummarizerConfig` for more details
    nonisolated(unsafe) public let options: [String: AnyHashable]

    // TODO: FXIOS-15123 - need confirm we want to pass these options, follow similar to S2S for now
    /// Default initializer with production configuration
    public init(instructions: String = "", options: [String: AnyHashable] = [
        "max_tokens": LiteLLMConfig.maxTokens,
        "model": LiteLLMConfig.apiModel,
        "stream": true
    ]) {
        self.instructions = instructions
        self.options = options
    }
}
