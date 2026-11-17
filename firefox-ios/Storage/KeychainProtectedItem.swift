// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security

public enum KeychainProtectedItem: CaseIterable, Sendable {
    // Preserve history during profile cleanup so reinstalls can be recognized.
    case installationHistory

    public var itemClass: CFString {
        switch self {
        case .installationHistory: kSecClassGenericPassword
        }
    }

    public var service: String {
        switch self {
        case .installationHistory: "org.mozilla.firefox.installation-history"
        }
    }

    public var account: String {
        switch self {
        case .installationHistory: "installation-history"
        }
    }

    func matches(attributes: [String: Any]) -> Bool {
        attributes[kSecAttrService as String] as? String == service
            && attributes[kSecAttrAccount as String] as? String == account
            && attributes[kSecAttrSynchronizable as String] as? Bool != true
    }
}
