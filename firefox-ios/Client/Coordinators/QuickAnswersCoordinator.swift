// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import QuickAnswersKit
import Common
import UIKit
import Shared

final class QuickAnswersCoordinator: BaseCoordinator, QuickAnswersNavigationHandler {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let onNavigate: (QuickAnswersNavigationType) -> Void
    private var shouldAnimateTransition: Bool {
        return !UIAccessibility.isReduceMotionEnabled
    }
    private let prefs: Prefs
    init(
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        router: Router,
        profile: Profile = AppContainer.shared.resolve(),
        onNavigate: @escaping (QuickAnswersNavigationType) -> Void,
    ) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onNavigate = onNavigate
        self.prefs = profile.prefs
        super.init(router: router)
    }

    func start() {
        let controller = QuickAnswersViewController(
            navigationHandler: self,
            windowUUID: windowUUID,
            themeManager: themeManager,
            prefs: prefs
        )
        router.present(controller, animated: shouldAnimateTransition)
    }

    // MARK: - QuickAnswersNavigationHandler
    func dismissQuickAnswers(with navigationType: QuickAnswersNavigationType?) {
        if let navigationType {
            onNavigate(navigationType)
        }
        router.dismiss(animated: shouldAnimateTransition)
        parentCoordinatorDelegate?.didFinish(from: self)
    }
}
