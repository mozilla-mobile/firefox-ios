// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

protocol LibraryCoordinatorDelegate: AnyObject {
    func didFinishLibrary(from coordinator: LibraryCoordinator)
}

class LibraryCoordinator: BaseCoordinator, LibraryPanelDelegate {
    private let profile: Profile
    private let tabManager: TabManager
    private let libraryViewController: LibraryViewController
    weak var parentCoordinator: (LibraryCoordinatorDelegate & LibraryPanelDelegate)?

    init(
        router: Router,
        profile: Profile = AppContainer.shared.resolve(),
        tabManager: TabManager = AppContainer.shared.resolve()
    ) {
        self.libraryViewController = LibraryViewController(profile: profile, tabManager: tabManager)
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
        self.router.setRootViewController(libraryViewController)
    }

    func start(with homepanelSection: Route.HomepanelSection) {
        libraryViewController.setupOpenPanel(panelType: homepanelSection.libraryPanel)
        libraryViewController.delegate = self
        libraryViewController.resetHistoryPanelPagination()
    }

    // MARK: - LibraryCoordinatorDelegate

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        parentCoordinator?.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
    }

    func libraryPanel(didSelectURL url: URL, visitType: Storage.VisitType) {
        parentCoordinator?.libraryPanel(didSelectURL: url, visitType: visitType)
    }

    func didFinish() {
        parentCoordinator?.didFinishLibrary(from: self)
    }
}
