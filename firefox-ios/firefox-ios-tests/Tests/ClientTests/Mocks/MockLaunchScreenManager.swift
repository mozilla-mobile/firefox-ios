// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import Common

class MockLaunchScreenViewModel: LaunchScreenViewModel {
    var introScreenManager: IntroScreenManager
    var updateViewModel: UpdateViewModel
    var surveySurfaceManager: SurveySurfaceManager
    var startLoadingCalled = 0
    var mockLaunchType: LaunchType?
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override init(
        windowUUID: WindowUUID,
        profile: Profile,
        messageManager: GleanPlumbMessageManagerProtocol = Experiments.messaging,
        onboardingModel: OnboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)
    ) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        self.updateViewModel = UpdateViewModel(profile: profile,
                                               model: onboardingModel,
                                               telemetryUtility: telemetryUtility,
                                               windowUUID: windowUUID)
        self.surveySurfaceManager = SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)
        super.init(windowUUID: windowUUID)
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
