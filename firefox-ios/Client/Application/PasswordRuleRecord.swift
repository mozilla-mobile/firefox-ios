// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct PasswordRuleRecord: Codable {
    let domain: String
    let passwordRules: String
    let id: String
    let lastModified: Int

    enum CodingKeys: String, CodingKey {
        case domain = "Domain"
        case passwordRules = "password-rules"
        case id
        case lastModified = "last_modified"
    }
}
