// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import QuickAnswersKit
import Common
import Shared
import UIKit

final class QuickAnswersCoordinator: BaseCoordinator, QuickAnswersNavigationHandler {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let prefs: Prefs
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let onNavigate: (QuickAnswersNavigationType) -> Void
    private var shouldAnimateTransition: Bool {
        return !UIAccessibility.isReduceMotionEnabled
    }

    init(
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        prefs: Prefs,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        router: Router,
        onNavigate: @escaping (QuickAnswersNavigationType) -> Void,
    ) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.prefs = prefs
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onNavigate = onNavigate
        super.init(router: router)
    }

    func start() {
        let controller = QuickAnswersViewController(
            navigationHandler: self,
            prefs: prefs,
            windowUUID: windowUUID,
            themeManager: themeManager,
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
