// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol Coordinator: AnyObject {
    var id: UUID { get }
    var childCoordinators: [Coordinator] { get }
    var router: Router { get }
    var logger: Logger { get }

    /// Determines whether this coordinator can be dismissed or not, in some cases the coordinator
    /// cannot be dismissed for example due to state saving.
    /// This isn't ideal for this pattern, but was deemed necessary to keep existing behavior while 
    /// moving away from previous pattern. By default, all coordinators should be dismissable.
    var isDismissable: Bool { get }

    /// Will hold the Route the coordinator was asked to navigate to in case the path could not be handled yet.
    var savedRoute: Route? { get set }

    /// Handle the Route, if able. This is implemented by each coordinator for Route they will handle.
    /// - Parameter route: The Route to navigate to
    func handle(route: Route)

    /// When the coordinator cannot handle this particular Route, it returns false.
    /// - Parameter route: The Route to navigate to.
    /// - Returns: true if the route can be handled.
    func canHandle(route: Route) -> Bool

    /// Searches for a coordinator to handle the given route by recursively checking `canHandle()` of all
    /// child coordinators.
    /// - Parameter route: The route to find a matching coordinator for.
    /// - Returns: A `Coordinator` that can handle the given `route`, or `nil` if none found.
    @discardableResult
    func find(route: Route) -> Coordinator?

    /// Convenience. Calls into `find()` to identify the `Coordinator` to handle a route, and then
    /// subsequently calls into `handle()` to perform the relevant actions on that route. Note that
    /// prior to handling the route any children coordinators will be dismissed.
    @discardableResult
    func findAndHandle(route: Route) -> Coordinator?

    func add(child coordinator: Coordinator)
    func remove(child coordinator: Coordinator?)
    func removeAllChildren()
}

extension Array where Element == Coordinator {
    subscript<T: Coordinator>(type: T.Type) -> T? {
        self.first(where: { $0 is T }) as? T
    }
}

extension Coordinator {
    /// Recursively performs an operation (defined by the supplied `action`)
    /// on the receiver and its entire sub-tree of child coordinators.
    func recurseChildCoordinators(_ action: (Coordinator) -> Void) {
        action(self)
        childCoordinators.forEach { $0.recurseChildCoordinators(action) }
    }
}
