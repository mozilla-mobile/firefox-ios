// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockSearchHandlerRouteCoordinator: BaseCoordinator {
    override func canHandle(route: Route) -> Bool {
        switch route {
        case .search:
            return true
        default:
            return false
        }
    }

    override func handle(route: Route) { }
}
