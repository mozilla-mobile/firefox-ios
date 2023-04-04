// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockLaunchScreenManager: LaunchScreenManager {
    var introScreenManager: IntroScreenManager
    var updateViewModel: UpdateViewModel
    var surveySurfaceManager: SurveySurfaceManager
    weak var delegate: LaunchFinishedLoadingDelegate?
    var mockLaunchType: LaunchType?
    var setOpenURLDelegateCalled = 0

    init(profile: Profile,
         surveySurfaceManager: SurveySurfaceManager = SurveySurfaceManager()) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        self.updateViewModel = UpdateViewModel(profile: profile)
        self.surveySurfaceManager = surveySurfaceManager
    }

    func getLaunchType(forType type: LaunchCoordinatorType) -> LaunchType? {
        return mockLaunchType
    }

    func set(openURLDelegate: OpenURLDelegate) {
        setOpenURLDelegateCalled += 1
    }
}
