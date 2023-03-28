// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol Coordinator {
    var id: UUID { get }
    var childCoordinators: [Coordinator] { get }
    var router: Router { get }

    func addChild(_ coordinator: Coordinator)
    func removeChild(_ coordinator: Coordinator?)
}

open class BaseCoordinator: Coordinator {
    var id: UUID = UUID()
    var childCoordinators: [Coordinator] = []
    var router: Router

    init(router: Router) {
        self.router = router
    }

    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: Coordinator?) {
        guard let coordinator = coordinator,
              let index = childCoordinators.firstIndex(where: { $0.id == coordinator.id })
        else { return }

        childCoordinators.remove(at: index)
    }
}
