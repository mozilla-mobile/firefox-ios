// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FeltPrivacyProtocol {
    func getPrivateModeState() -> Bool
    func setPrivateModeState(to state: Bool)
}

class FeltPrivacyManager {
    private var isInPrivateMode: Bool

    init(isInPrivateMode: Bool) {
        self.isInPrivateMode = isInPrivateMode
    }

    func getPrivateModeState() -> Bool {
        return isInPrivateMode
    }

    func setPrivateModeState(to newState: Bool) {
        isInPrivateMode = newState
    }
}
