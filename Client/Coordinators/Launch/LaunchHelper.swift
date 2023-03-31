// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LaunchHelper {
    var introScreenManager: IntroScreenManager
    var updateViewModel: UpdateViewModel
    var surveySurfaceManager: SurveySurfaceManager
    var isIphone: Bool

    init(profile: Profile,
         openURLDelegate: OpenURLDelegate,
         isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        self.updateViewModel = UpdateViewModel(profile: profile)

        self.surveySurfaceManager = SurveySurfaceManager()
        self.surveySurfaceManager.openURLDelegate = openURLDelegate

        self.isIphone = isIphone
    }

    var launchFromSceneCoordinator: Bool {
        return isIphone
    }

    var launchType: LaunchType? {
        return LaunchType.getLaunchType(introScreenManager: introScreenManager,
                                        updateViewModel: updateViewModel,
                                        surveySurfaceManager: surveySurfaceManager)
    }
}
