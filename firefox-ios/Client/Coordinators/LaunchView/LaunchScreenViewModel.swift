// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol LaunchFinishedLoadingDelegate: AnyObject {
    func launchWith(launchType: LaunchType)
    func launchBrowser()
}

class LaunchScreenViewModel {
    private var introScreenManager: IntroScreenManager
    private var updateViewModel: UpdateViewModel
    private var surveySurfaceManager: SurveySurfaceManager

    weak var delegate: LaunchFinishedLoadingDelegate?

    init(profile: Profile = AppContainer.shared.resolve(),
         messageManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared,
         onboardingModel: OnboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        self.updateViewModel = UpdateViewModel(profile: profile,
                                               model: onboardingModel,
                                               telemetryUtility: telemetryUtility)
        self.surveySurfaceManager = SurveySurfaceManager(and: messageManager)
    }

    func startLoading(appVersion: String = AppInfo.appVersion) async {
        await loadLaunchType(appVersion: appVersion)
    }

    private func loadLaunchType(appVersion: String) async {
        var launchType: LaunchType?
        if introScreenManager.shouldShowIntroScreen {
            launchType = .intro(manager: introScreenManager)
        } else if updateViewModel.shouldShowUpdateSheet(appVersion: appVersion),
                  await updateViewModel.hasSyncableAccount() {
            launchType = .update(viewModel: updateViewModel)
        } else if surveySurfaceManager.shouldShowSurveySurface {
            launchType = .survey(manager: surveySurfaceManager)
        }

        if let launchType = launchType {
            self.delegate?.launchWith(launchType: launchType)
        } else {
            self.delegate?.launchBrowser()
        }
    }
}
