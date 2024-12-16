// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import enum MozillaAppServices.VisitType

protocol ReadingListNavigationHandler: AnyObject, LibraryPanelCoordinatorDelegate {
    func openUrl(_ url: URL, visitType: VisitType)
}

class ReadingListCoordinator: BaseCoordinator, ReadingListNavigationHandler {
    // MARK: - Properties

    private weak var parentCoordinator: LibraryCoordinatorDelegate?
    private weak var navigationHandler: LibraryNavigationHandler?

    // MARK: - Initializers

    init(
        parentCoordinator: LibraryCoordinatorDelegate?,
        navigationHandler: LibraryNavigationHandler?,
        router: Router
    ) {
        self.parentCoordinator = parentCoordinator
        self.navigationHandler = navigationHandler
        super.init(router: router)
    }

    // MARK: - ReadingListNavigationHandler

    func openUrl(_ url: URL, visitType: VisitType) {
        parentCoordinator?.libraryPanel(didSelectURL: url, visitType: visitType)
    }

    func shareLibraryItem(url: URL, sourceView: UIView) {
        navigationHandler?.shareLibraryItem(url: url, sourceView: sourceView)
    }
}
