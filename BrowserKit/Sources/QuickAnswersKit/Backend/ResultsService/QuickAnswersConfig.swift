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
    /// Default initializer with production configuration.
    /// - Parameters:
    ///   - model: The provider model that backs Quick Answers.
    ///   - instructions: The system prompt instructions injected into the request. Empty by default.
    ///   - options: Additional inference options. `model` is always overridden from the `model` parameter.
    public init(
        model: QuickAnswersModel = .exa,
        instructions: String = "",
        options: [String: AnyHashable] = [
            "stream": false
        ]
    ) {
        self.instructions = instructions
        var options = options
        options["model"] = model.rawValue
        self.options = options
    }
}
