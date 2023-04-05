// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

struct MockLaunchManager: LaunchManager {
    var canLaunchFromSceneCoordinator: Bool = false
    var mockLaunchType: LaunchType?

    func getLaunchType(appVersion: String) -> LaunchType? {
        return mockLaunchType
    }
}
