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

                // Dismiss any child of the matching coordinator that handles a route
                for child in matchingCoordinator.childCoordinators {
                    guard child.isDismissable else { continue }
                    guard shouldDismiss(coordinator: matchingCoordinator, for: route) else { continue }

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

    // Tentative fix for FXIOS-7631; this fixes the bug but may warrant add'tl team discussion/investigation to better
    // understand the ideal way of addressing this. Related PR: https://github.com/mozilla-mobile/firefox-ios/pull/16789
    private func shouldDismiss(coordinator: Coordinator, for route: Route) -> Bool {
        switch route {
        case .defaultBrowser(section: .tutorial):
            return !(coordinator is BrowserCoordinator)
        default:
            return true
        }
    }
}
