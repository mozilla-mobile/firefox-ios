// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Reference: https://github.com/ecosia/core/blob/main/common/js/universal/markets.js

public struct Market: Decodable {
    public let value: Local
    public let label: String
    public let languageInLabel: Bool

    public init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        value = try root.decode(Local.self, forKey: .value)
        label = try root.decode(String.self, forKey: .label)
        if let stringValue = try? root.decode(String.self, forKey: .languageInLabel) {
            languageInLabel = Bool(stringValue) ?? false
        } else {
            languageInLabel = false
        }
    }

    private enum CodingKeys: String, CodingKey {
        case value, label, languageInLabel
    }
}
