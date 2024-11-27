// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockLaunchCoordinatorDelegate: LaunchCoordinatorDelegate {
    var didFinishCalledCount = 0
    weak var savedDidFinishCoordinator: LaunchCoordinator?

    func didFinishLaunch(from coordinator: LaunchCoordinator) {
        didFinishCalledCount += 1
        savedDidFinishCoordinator = coordinator
    }

    func didFinishTermsOfService(from coordinator: LaunchCoordinator) {
    }
}
