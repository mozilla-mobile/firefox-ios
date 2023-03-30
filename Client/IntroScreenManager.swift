// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct IntroScreenManager {
    var prefs: Prefs

    var shouldShowIntroScreen: Bool {
        prefs.intForKey(PrefsKeys.IntroSeen) == nil
    }

    func didSeeIntroScreen() {
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
    }
}
