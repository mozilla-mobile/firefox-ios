// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LiteLLMResponse<ProviderFields: Codable & Sendable>: Codable {
    let id: String
    let choices: [LiteLLMChoice<ProviderFields>]
}

struct LiteLLMChoice<ProviderFields: Codable & Sendable>: Codable {
    let index: Int
    let message: LiteLLMMessage<ProviderFields>?
    let delta: LiteLLMMessage<ProviderFields>?
    let finishReason: String?
}
