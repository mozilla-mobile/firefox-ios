// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import VoiceSearchKit
import Common
import UIKit

final class VoiceSearchCoordinator: BaseCoordinator, VoiceSearchNavigationHandler {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let onNavigateToURL: (URL) -> Void
    private let onNavigateToSearch: (String) -> Void
    private lazy var controller = VoiceSearchViewController(
        navigationHandler: self,
        windowUUID: windowUUID,
        themeManager: themeManager
    )
    private var shouldAnimateTransition: Bool {
        return !UIAccessibility.isReduceMotionEnabled
    }

    init(
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        router: Router,
        onNavigateToURL: @escaping (URL) -> Void,
        onNavigateToSearch: @escaping (String) -> Void
    ) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onNavigateToURL = onNavigateToURL
        self.onNavigateToSearch = onNavigateToSearch
        super.init(router: router)
    }

    func start() {
        router.present(controller, animated: shouldAnimateTransition)
    }

    // MARK: - VoiceSearchNavigationHandler
    func dismissVoiceSearch() {
        router.dismiss(animated: shouldAnimateTransition)
        parentCoordinatorDelegate?.didFinish(from: self)
    }

    func navigateToURL(_ url: URL) {
        onNavigateToURL(url)
        dismissVoiceSearch()
    }

    func navigateToSearchResult(_ query: String) {
        onNavigateToSearch(query)
        dismissVoiceSearch()
    }
}
