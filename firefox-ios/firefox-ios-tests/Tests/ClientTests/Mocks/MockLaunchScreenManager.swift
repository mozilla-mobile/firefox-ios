// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockLaunchScreenViewModel: LaunchScreenViewModel {
    var introScreenManager: IntroScreenManager
    var updateViewModel: UpdateViewModel
    var surveySurfaceManager: SurveySurfaceManager
    var startLoadingCalled = 0
    var mockLaunchType: LaunchType?

    override init(
        profile: Profile,
        messageManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared,
        onboardingModel: OnboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)
    ) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        self.updateViewModel = UpdateViewModel(profile: profile,
                                               model: onboardingModel,
                                               telemetryUtility: telemetryUtility)
        self.surveySurfaceManager = SurveySurfaceManager(and: messageManager)
    }

    override func startLoading(appVersion: String) async {
        startLoadingCalled += 1
        if let mockLaunchType = mockLaunchType {
            delegate?.launchWith(launchType: mockLaunchType)
        } else {
            delegate?.launchBrowser()
        }
    }
}
