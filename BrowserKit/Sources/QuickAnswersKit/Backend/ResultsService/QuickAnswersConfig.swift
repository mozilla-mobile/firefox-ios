// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit

// TODO: FXIOS-15196 We may not need a configuration if we only want to pass in the transcription,
// may need to refactor `LiteLLMClient`
/// A configuration container for the quick answers results feature.
public struct QuickAnswersConfig: LLMConfig, Sendable {
    public let instructions = ""
    // FIXME: FXIOS-13417 We should strongly type options in the future so they can be any Sendable & Hashable
    // See `SummarizerConfig` for more details
    nonisolated(unsafe) public let options: [String: AnyHashable] = [:]
}
