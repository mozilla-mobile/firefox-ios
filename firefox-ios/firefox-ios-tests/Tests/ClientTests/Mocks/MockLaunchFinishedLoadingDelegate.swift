// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockLaunchFinishedLoadingDelegate: LaunchFinishedLoadingDelegate {
    var savedLaunchType: LaunchType?
    var launchWithTypeCalled = 0
    var launchBrowserCalled = 0
    var finishedLoadingLaunchOrderCalled = 0

    func launchWith(launchType: LaunchType) {
        launchWithTypeCalled += 1
        savedLaunchType = launchType
    }

    func launchBrowser() {
        launchBrowserCalled += 1
    }

    func finishedLoadingLaunchOrder() {
        finishedLoadingLaunchOrderCalled += 1
    }
}
