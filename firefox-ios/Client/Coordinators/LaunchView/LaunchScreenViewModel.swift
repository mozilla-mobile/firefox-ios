// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol LaunchFinishedLoadingDelegate: AnyObject {
    func launchWith(launchType: LaunchType)
    func launchBrowser()
    func finishedLoadingLaunchOrder()
}

class LaunchScreenViewModel {
    private var termsOfServiceManager: TermsOfServiceManager
    private var introScreenManager: IntroScreenManager
    private var updateViewModel: UpdateViewModel
    private var surveySurfaceManager: SurveySurfaceManager
    private var profile: Profile

    // order of screens to showing at launch
    private(set) var launchOrder: [LaunchType]?

    weak var delegate: LaunchFinishedLoadingDelegate?

    init(windowUUID: WindowUUID,
         profile: Profile = AppContainer.shared.resolve(),
         messageManager: GleanPlumbMessageManagerProtocol = Experiments.messaging,
         onboardingModel: OnboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)) {
        self.profile = profile
        self.termsOfServiceManager = TermsOfServiceManager(prefs: profile.prefs)
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        self.updateViewModel = UpdateViewModel(profile: profile,
                                               model: onboardingModel,
                                               telemetryUtility: telemetryUtility,
                                               windowUUID: windowUUID)
        self.surveySurfaceManager = SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)
    }

    func getSplashScreenExperimentHasShown() -> Bool {
        profile.prefs.boolForKey(PrefsKeys.splashScreenShownKey) ?? false
    }

    func setSplashScreenExperimentHasShown() {
        profile.prefs.setBool(true, forKey: PrefsKeys.splashScreenShownKey)
    }

    func startLoading(appVersion: String = AppInfo.appVersion) async {
        await loadLaunchType(appVersion: appVersion)
    }

    func loadNextLaunchType() {
        guard let launches = launchOrder else { return }

        if let launchType = launches.first {
            delegate?.launchWith(launchType: launchType)
            launchOrder?.removeFirst()
        } else {
            self.delegate?.launchBrowser()
        }
    }

    private func loadLaunchType(appVersion: String) async {
        var launchOrder = [LaunchType]()

        if introScreenManager.shouldShowIntroScreen {
            if termsOfServiceManager.shouldShowScreen {
                launchOrder.append(.termsOfService(manager: termsOfServiceManager))
            }

            launchOrder.append(.intro(manager: introScreenManager))
        } else if updateViewModel.shouldShowUpdateSheet(appVersion: appVersion),
                  await updateViewModel.hasSyncableAccount() {
            launchOrder.append(.update(viewModel: updateViewModel))
        } else if surveySurfaceManager.shouldShowSurveySurface {
            launchOrder.append(.survey(manager: surveySurfaceManager))
        }

        if !launchOrder.isEmpty {
            self.launchOrder = launchOrder
            self.delegate?.finishedLoadingLaunchOrder()
        } else {
            self.delegate?.launchBrowser()
        }
    }
}
