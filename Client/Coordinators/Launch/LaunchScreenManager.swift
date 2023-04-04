// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol LaunchFinishedLoadingDelegate: AnyObject {
    func launchTypeLoaded()
}

protocol LaunchScreenManager {
    var introScreenManager: IntroScreenManager { get }
    var updateViewModel: UpdateViewModel { get }
    var surveySurfaceManager: SurveySurfaceManager { get }
    var delegate: LaunchFinishedLoadingDelegate? { get set }

    func getLaunchType(forType type: LaunchCoordinatorType) -> LaunchType?
    func set(openURLDelegate: OpenURLDelegate)
}

class DefaultLaunchScreenManager: LaunchScreenManager {
    var introScreenManager: IntroScreenManager
    var updateViewModel: UpdateViewModel
    var surveySurfaceManager: SurveySurfaceManager

    weak var delegate: LaunchFinishedLoadingDelegate?
    private var launchType: LaunchType?

    init(
        profile: Profile = AppContainer.shared.resolve(),
        messageManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared,
        appVersion: String = AppInfo.appVersion
    ) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        self.updateViewModel = UpdateViewModel(profile: profile)
        self.surveySurfaceManager = SurveySurfaceManager(and: messageManager)

        Task {
            await loadLaunchType(appVersion: appVersion)
        }
    }

    func getLaunchType(forType type: LaunchCoordinatorType) -> LaunchType? {
        if let launchType = launchType {
            return launchType.canLaunch(fromType: type) ? launchType: nil
        } else {
            return nil
        }
    }

    func set(openURLDelegate: OpenURLDelegate) {
        self.surveySurfaceManager.openURLDelegate = openURLDelegate
    }

    private func loadLaunchType(appVersion: String) async {
        if introScreenManager.shouldShowIntroScreen {
            launchType = .intro
        } else if updateViewModel.shouldShowUpdateSheet(appVersion: appVersion),
                  await updateViewModel.hasSyncableAccount() {
            launchType = .update
        } else if surveySurfaceManager.shouldShowSurveySurface {
            launchType = .survey
        } else {
            launchType = nil
        }

        DispatchQueue.main.async {
            self.delegate?.launchTypeLoaded()
        }
    }
}
