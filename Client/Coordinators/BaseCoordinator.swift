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
    var isDismissable: Bool { true }
    var newlyAdded = false
    private var mainQueue: DispatchQueueInterface

    init(router: Router,
         logger: Logger = DefaultLogger.shared,
         mainQueue: DispatchQueueInterface = DispatchQueue.main) {
        self.router = router
        self.logger = logger
        self.mainQueue = mainQueue
    }

    func add(child coordinator: Coordinator) {
        childCoordinators.append(coordinator)

        // Check first whether, during the recursive findAndHandle(route:), we have just added
        // new children to this coordinator. If so, we want to skip dismissal (we shouldn't ever
        // immediately dismiss coordinators that were just added and about to appear).
        // Will be removed as part of larger refactors in [FXIOS-7641].
        coordinator.newlyAdded = true
        mainQueue.async { [weak coordinator] in coordinator?.newlyAdded = false }
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

                // Dismiss any child of the matching coordinator that handles a route
                for child in matchingCoordinator.childCoordinators {
                    guard child.isDismissable else { continue }

                    // Check first whether, during the recursive findAndHandle(route:), we have just added
                    // this child to the coordinator. If so, we want to skip dismissal (we shouldn't ever
                    // immediately dismiss coordinators that were just added and about to appear).
                    // Will be removed as part of larger refactors in [FXIOS-7641].
                    guard !child.newlyAdded else { continue }

                    matchingCoordinator.router.dismiss()
                    matchingCoordinator.remove(child: child)
                }

                return matchingCoordinator
            }
        }

        // If no matching coordinator is found, return nil and save the Route to be passed along when it next navigates
        savedRoute = route
        logger.log("Saved a route", level: .info, category: .coordinator)
        return nil
    }
}
