// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockLaunchFinishedLoadingDelegate: LaunchFinishedLoadingDelegate {
    // MARK: - Properties
    var savedLaunchType: LaunchType?
    var launchWithTypeCalled = 0
    var launchBrowserCalled = 0
    var finishedLoadingLaunchOrderCalled = 0

    // MARK: - Call Tracking
    private var launchWithTypeCallHistory: [LaunchType] = []
    private var launchBrowserCallHistory: [Date] = []
    private var finishedLoadingCallHistory: [Date] = []

    func launchWith(launchType: LaunchType) {
        launchWithTypeCalled += 1
        savedLaunchType = launchType
        launchWithTypeCallHistory.append(launchType)
    }

    func launchBrowser() {
        launchBrowserCalled += 1
        launchBrowserCallHistory.append(Date())
    }

    func finishedLoadingLaunchOrder() {
        finishedLoadingLaunchOrderCalled += 1
        finishedLoadingCallHistory.append(Date())
    }

    // MARK: - Test Helper Methods

    func verifyLaunchWithCalled(with launchType: LaunchType) -> Bool {
        return launchWithTypeCallHistory.contains { savedType in
            switch (savedType, launchType) {
            case (.intro, .intro), (.update, .update), (.survey, .survey),
                 (.defaultBrowser, .defaultBrowser), (.termsOfService, .termsOfService):
                return true
            default:
                return false
            }
        }
    }
}
