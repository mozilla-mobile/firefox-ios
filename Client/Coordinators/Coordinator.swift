// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol Coordinator {
    var id: UUID { get }
    var childCoordinators: [Coordinator] { get }
    var router: Router { get }

    func add(child coordinator: Coordinator)
    func remove(child coordinator: Coordinator?)

    func handle(route: Route) -> Bool

    @discardableResult
    func findAndHandle(route: Route) -> Coordinator?
}

extension Coordinator {
    /// Finds a coordinator that can handle a given route by recursively searching through the current coordinator's child coordinators.
    /// - Parameter route: The route to find a matching coordinator for.
    /// - Returns: An optional `Coordinator` instance that can handle the given `route`, or `nil` if no such coordinator was found.
    ///
    /// - DiscardableResult: The result of this method is marked as `@discardableResult` because the caller may choose not to use the returned
    /// `Coordinator` instance, which is safe to do.
    @discardableResult
    func findAndHandle(route: Route) -> Coordinator? {
        // Check if the current coordinator can handle the route.
        if handle(route: route) {
            return self
        }

        // If not, recursively search through child coordinators.
        for childCoordinator in childCoordinators {
            if let matchingCoordinator = childCoordinator.findAndHandle(route: route) {
                return matchingCoordinator
            }
        }

        // If no matching coordinator is found, return nil.
        return nil
    }
}

open class BaseCoordinator: Coordinator {
    var id = UUID()
    var childCoordinators: [Coordinator] = []
    var router: Router

    init(router: Router) {
        self.router = router
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
}

extension Array where Element == Coordinator {
    subscript<T: Coordinator>(type: T.Type) -> T? {
        self.first(where: { $0 is T }) as? T
    }
}
