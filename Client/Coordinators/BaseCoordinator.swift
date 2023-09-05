// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

open class BaseCoordinator: NSObject, Coordinator {
    var savedRoute: Route?
    var id = UUID()
    var childCoordinators: [Coordinator] = []
    var router: Router
    var logger: Logger

    init(router: Router,
         logger: Logger = DefaultLogger.shared) {
        self.router = router
        self.logger = logger
    }

    func add(child coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func remove(child coordinator: Coordinator?) {
        guard let coordinator = coordinator,
              let index = childCoordinators.firstIndex(where: { $0.id == coordinator.id })
        else { return }

        childCoordinators.remove(at: index)
    }

    func handle(route: Route) -> Bool {
        return false
    }

    @discardableResult
    func findAndHandle(route: Route) -> Coordinator? {
        // If the app crashed last session then we abandon the deeplink
        guard !logger.crashedLastLaunch else { return nil }

        // Check if the current coordinator can handle the route.
        if handle(route: route) {
            savedRoute = nil
            return self
        }

        // If not, recursively search through child coordinators.
        for childCoordinator in childCoordinators {
            if let matchingCoordinator = childCoordinator.findAndHandle(route: route) {
                savedRoute = nil
                return matchingCoordinator
            }
        }

        // If no matching coordinator is found, return nil and save the Route to be passed along when it next navigates
        savedRoute = route
        logger.log("Saved a route", level: .info, category: .coordinator)
        return nil
    }
}
