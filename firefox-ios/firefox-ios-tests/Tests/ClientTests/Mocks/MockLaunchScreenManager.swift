// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import Common

class MockLaunchScreenViewModel: LaunchScreenViewModel {
    // MARK: - Properties
    var introScreenManager: IntroScreenManager
    var surveySurfaceManager: SurveySurfaceManager
    var startLoadingCalled = 0
    var loadNextLaunchTypeCalled = 0
    var mockLaunchType: LaunchType?
    var mockAppVersion: String?
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    // MARK: - Call Tracking
    private var startLoadingCallHistory: [String] = []
    private var loadNextLaunchTypeCallHistory: [Date] = []

    override init(
        windowUUID: WindowUUID,
        profile: Profile = AppContainer.shared.resolve(),
        messageManager: GleanPlumbMessageManagerProtocol = Experiments.messaging,
        introScreenManager: IntroScreenManagerProtocol? = nil
    ) {
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        self.surveySurfaceManager = SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)
        super.init(windowUUID: windowUUID,
                   profile: profile,
                   messageManager: messageManager,
                   introScreenManager: introScreenManager)
    }

    override func startLoading(appVersion: String) {
        startLoadingCalled += 1
        startLoadingCallHistory.append(appVersion)
        mockAppVersion = appVersion
        if let mockLaunchType = mockLaunchType {
            delegate?.launchWith(launchType: mockLaunchType)
        } else {
            delegate?.launchBrowser()
        }
    }

    override func loadNextLaunchType() {
        loadNextLaunchTypeCalled += 1
        loadNextLaunchTypeCallHistory.append(Date())
        if let mockLaunchType = mockLaunchType {
            delegate?.launchWith(launchType: mockLaunchType)
        } else {
            delegate?.launchBrowser()
        }
    }
}
