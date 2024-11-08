// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockParentCoordinator: ParentCoordinatorDelegate {
    var didFinishCalled = 0

    func didFinish(from childCoordinator: Coordinator) {
        didFinishCalled += 1
    }
}
