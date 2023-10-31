// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol TabsNavigationHandler: AnyObject {
    func addToBookmarks(_ url: URL)
    func sendToDevice(_ url: URL)
}

class TabsCoordinator: BaseCoordinator, TabsNavigationHandler {
    // MARK: - Properties

    private weak var parentCoordinator: TabTrayCoordinatorDelegate?

    // MARK: - Initializers

    init(
        parentCoordinator: TabTrayCoordinatorDelegate?,
        router: Router
    ) {
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - RegularTabsNavigationHandler

    func addToBookmarks(_ url: URL) {}
    func sendToDevice(_ url: URL) {}
}
