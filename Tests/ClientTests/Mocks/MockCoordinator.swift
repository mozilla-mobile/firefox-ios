// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
@testable import Client

class MockCoordinator: Coordinator {
    var id = UUID()
    var childCoordinators: [Coordinator] = []
    var router: Router
    var savedRoute: Route?
    var logger: Logger = MockLogger()

    var addChildCalled = 0
    var removedChildCalled = 0
    var handleRouteCalled = 0
    var findRouteCalled = 0

    init(router: MockRouter) {
        self.router = router
    }

    func add(child coordinator: Coordinator) {
        addChildCalled += 1
    }

    func remove(child coordinator: Coordinator?) {
        removedChildCalled += 1
    }

    func handle(route: Route) -> Bool {
        handleRouteCalled += 1
        return false
    }

    @discardableResult
    func findAndHandle(route: Route) -> Coordinator? {
        findRouteCalled += 1
        savedRoute = route
        return nil
    }
}
