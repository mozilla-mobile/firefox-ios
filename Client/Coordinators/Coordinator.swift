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

    /// Will hold the Route the coordinator was asked to navigate to in case the path could not be handled yet.
    var savedRoute: Route? { get set }

    /// Handle the Route, this is implemented by each coordinator for Route they will handle.
    /// When the coordinator cannot handle this particular Route, it returns false.
    /// - Parameter route: The Route to navigate to
    /// - Returns: True when the Route was handled
    func handle(route: Route) -> Bool

    /// Finds a coordinator that can handle a given route by recursively searching through the current coordinator's child coordinators.
    /// - Parameter route: The route to find a matching coordinator for.
    /// - Returns: An optional `Coordinator` instance that can handle the given `route`, or `nil` if no such coordinator was found.
    ///
    /// - DiscardableResult: The result of this method is marked as `@discardableResult` because the caller may choose not to use the returned
    /// `Coordinator` instance, which is safe to do.
    @discardableResult
    func findAndHandle(route: Route) -> Coordinator?

    func add(child coordinator: Coordinator)
    func remove(child coordinator: Coordinator?)
}

extension Array where Element == Coordinator {
    subscript<T: Coordinator>(type: T.Type) -> T? {
        self.first(where: { $0 is T }) as? T
    }
}
