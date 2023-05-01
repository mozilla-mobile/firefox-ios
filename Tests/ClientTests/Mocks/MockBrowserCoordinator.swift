// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockBrowserCoordinator: BaseCoordinator {
    var findRouteCalled = 0
    var savedRoute: Route?

    func find(route: Route) -> Coordinator? {
        findRouteCalled += 1
        savedRoute = route
        return nil
    }
}
