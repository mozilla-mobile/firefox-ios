// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LiteLLMStreamResponse: Codable {
    let id: String
    let created: Int
    let model: String
    let object: String
    let choices: [StreamChoice]
}

struct StreamChoice: Codable {
    let index: Int
    let delta: Delta
}

struct Delta: Codable {
    let role: String?
    let content: String?
}
