// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

// Helps manage the launch of different onboardings, defined in LaunchType
protocol LaunchManager {
    var canLaunchFromSceneCoordinator: Bool { get }
    func getLaunchType(appVersion: String) -> LaunchType?
}

extension LaunchManager {
    func getLaunchType(appVersion: String = AppInfo.appVersion) -> LaunchType? {
        getLaunchType(appVersion: appVersion)
    }
}

struct DefaultLaunchManager: LaunchManager {
    var introScreenManager: IntroScreenManager
    var updateViewModel: UpdateViewModel
    var surveySurfaceManager: SurveySurfaceManager
    var isIphone: Bool

    init(profile: Profile,
         openURLDelegate: OpenURLDelegate?,
         messageManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared,
         isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        self.updateViewModel = UpdateViewModel(profile: profile)

        self.surveySurfaceManager = SurveySurfaceManager(and: messageManager)
        self.surveySurfaceManager.openURLDelegate = openURLDelegate

        self.isIphone = isIphone
    }

    /// We launch onboardings from the scene coordinator for iPhone, otherwise we launch them from BrowserCoordinator
    var canLaunchFromSceneCoordinator: Bool {
        return isIphone
    }

    func getLaunchType(appVersion: String = AppInfo.appVersion) -> LaunchType? {
        if introScreenManager.shouldShowIntroScreen {
            return .intro
        } else if updateViewModel.shouldShowUpdateSheet(appVersion: appVersion) {
            return .update
        } else if surveySurfaceManager.shouldShowSurveySurface {
            return .survey
        } else {
            return nil
        }
    }
}
