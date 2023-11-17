// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
// Ecosia: Import Core
import Core

struct IntroScreenManager {
    var prefs: Prefs

    var shouldShowIntroScreen: Bool {
        /* Ecosia
           The `PrefsKeys.IntroSeen` is also used to flag the DefaultBrowser card showing
           for some reason. So the in the version based on top of the v104, the check to
           show the IntroScreen/Onboarding is perfomed at AppDelegate level
           checking against the `User.shared.firstTime` flag.
           We are now performing the check here so the whole coordinators/managers patters will work
           as usual.
         */
        // prefs.intForKey(PrefsKeys.IntroSeen) == nil
        User.shared.firstTime
    }

    func didSeeIntroScreen() {
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
    }
}
