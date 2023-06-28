// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LoginOnboarding {
    static let HasSeenLoginOnboardingKey = "HasSeenLoginOnboarding"

    static func shouldShow() -> Bool {
        return UserDefaults.standard.bool(forKey: HasSeenLoginOnboardingKey) == false
    }

    static func setShown() {
        UserDefaults.standard.set(true, forKey: HasSeenLoginOnboardingKey)
    }
}
