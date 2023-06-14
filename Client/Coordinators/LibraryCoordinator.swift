// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

protocol LibraryCoordinatorDelegate: AnyObject {}

class LibraryCoordinator: BaseCoordinator, LibraryPanelDelegate {
    private let profile: Profile
    private let tabManager: TabManager
    private var libraryViewController: LibraryViewController!
    weak var parentCoordinator: LibraryCoordinatorDelegate?

    init(
        router: Router,
        profile: Profile = AppContainer.shared.resolve(),
        tabManager: TabManager = AppContainer.shared.resolve()
    ) {
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
    }

    private func toLibraryPanel(_ homepanelSection: Route.HomepanelSection) -> LibraryPanelType {
        switch homepanelSection {
        case .bookmarks: return .bookmarks
        case .history: return .history
        case .readingList: return .readingList
        case .downloads: return .downloads
        default: return . bookmarks
        }
    }

    func start(with homepanelSection: Route.HomepanelSection) {
        libraryViewController = LibraryViewController(profile: profile, tabManager: tabManager)
        libraryViewController.setupOpenPanel(panelType: toLibraryPanel(homepanelSection))
        libraryViewController.resetHistoryPanelPagination()
        libraryViewController.delegate = self

        router.setRootViewController(libraryViewController, hideBar: false, animated: false)
    }

    func libraryPanelDidRequestToSignIn() {
        // TODO: Will be handled by FXIOS-6604
    }

    func libraryPanelDidRequestToCreateAccount() {
        // TODO: Will be handled by FXIOS-6604
    }

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        // TODO: Will be handled by FXIOS-6604
    }

    func libraryPanel(didSelectURLString url: String, visitType: VisitType) {
        // TODO: Will be handled by FXIOS-6604
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        // TODO: Will be handled by FXIOS-6604
    }
}
