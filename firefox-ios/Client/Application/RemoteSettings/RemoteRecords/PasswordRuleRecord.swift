// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol RemoteDataTypeRecord: Codable, Equatable {}

struct PasswordRuleRecord: RemoteDataTypeRecord {
    // Unix timestamp represents milliseconds since the Unix Epoch time
    let lastModified: Int
    let domain: String
    let passwordRules: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case domain = "Domain"
        case passwordRules = "password-rules"
        case id
        case lastModified = "last_modified"
    }

    public static func == (lhs: PasswordRuleRecord, rhs: PasswordRuleRecord) -> Bool {
        return lhs.domain == rhs.domain &&
               lhs.passwordRules == rhs.passwordRules &&
               lhs.id == rhs.id &&
               lhs.lastModified == rhs.lastModified
    }
}
