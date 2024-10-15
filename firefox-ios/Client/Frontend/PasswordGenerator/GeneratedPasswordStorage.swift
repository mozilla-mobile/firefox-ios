// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol GeneratedPasswordStorageProtocol: AnyObject {
    func setPasswordForOrigin(origin: String, password: String)
    func deletePasswordForOrigin(origin: String)
    func getPasswordForOrigin(origin: String) -> String?
}

class GeneratedPasswordStorage: GeneratedPasswordStorageProtocol {
    private var originToPasswordMapping: [String: String] =  [:]

    func deletePasswordForOrigin(origin: String) {
        originToPasswordMapping[origin] = nil
    }

    func setPasswordForOrigin(origin: String, password: String) {
        originToPasswordMapping[origin] = password
    }

    func getPasswordForOrigin(origin: String) -> String? {
        return originToPasswordMapping[origin]
    }
}
