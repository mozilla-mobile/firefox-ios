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
    }

    func remove(child coordinator: Coordinator?) {
        guard let coordinator = coordinator,
              let index = childCoordinators.firstIndex(where: { $0.id == coordinator.id })
        else { return }

        childCoordinators.remove(at: index)
    }

    func removeAllChildren() {
        childCoordinators.removeAll()
    }

    func canHandle(route: Route) -> Bool {
        return false
    }

    func handle(route: Route) { }

    @discardableResult
    func findAndHandle(route: Route) -> Coordinator? {
        guard let matchingCoordinator = find(route: route) else { return nil }

        // Dismiss any child of the matching coordinator that handles a route
        for child in matchingCoordinator.childCoordinators {
            guard child.isDismissable else { continue }

            logger.log("Dismissing child of the matching coordinator", level: .debug, category: .coordinator)
            matchingCoordinator.router.dismiss()
            matchingCoordinator.remove(child: child)
        }

        matchingCoordinator.handle(route: route)
        return matchingCoordinator
    }

    @discardableResult
    func find(route: Route) -> Coordinator? {
        // Check if the current coordinator can handle the route.
        if canHandle(route: route) {
            logger.log("Can handle the route with \(self)", level: .debug, category: .coordinator)
            savedRoute = nil
            return self
        }

        // If not, recursively search through child coordinators.
        for childCoordinator in childCoordinators {
            if let matchingCoordinator = childCoordinator.find(route: route) {
                savedRoute = nil

                logger.log("Can handle route with child coordinator \(matchingCoordinator)",
                           level: .debug,
                           category: .coordinator)
                return matchingCoordinator
            }
        }

        // If no matching coordinator is found, return nil and save the Route to be passed along when it next navigates
        savedRoute = route
        logger.log("No coordinator found, saved a route", level: .info, category: .coordinator)
        return nil
    }
}
