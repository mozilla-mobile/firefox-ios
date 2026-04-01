// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import LLMKit

final class MockConfig: LLMConfig {
    let instructions: String
    // FIXME: FXIOS-13417 We should strongly type options in the future so they can be any Sendable & Hashable
    nonisolated(unsafe) let options: [String: AnyHashable]

    init(instructions: String, options: [String: AnyHashable]) {
        self.instructions = instructions
        self.options = options
    }
}
