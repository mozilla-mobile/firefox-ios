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
    private let transitionType: QuickAnswersTransitionType
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
        transitionType: QuickAnswersTransitionType,
        onNavigate: @escaping (QuickAnswersNavigationType) -> Void,
    ) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.prefs = prefs
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.transitionType = transitionType
        self.onNavigate = onNavigate
        super.init(router: router)
    }

    func start() {
        let controller = QuickAnswersViewController(
            navigationHandler: self,
            transitionType: transitionType,
            prefs: prefs,
            windowUUID: windowUUID,
            themeManager: themeManager,
            model: nimbusModel(),
            learnMoreURL: SupportUtils.URLForTopic("quick-answers-mobile"),
        )
        router.present(controller, animated: shouldAnimateTransition)
    }

    /// Reads the Nimbus-configured Quick Answers model and maps it to the `QuickAnswersKit` enum,
    /// falling back to `.exa` if the value is unrecognized.
    private func nimbusModel() -> QuickAnswersModel {
        let rawValue = FxNimbus.shared.features.quickAnswersFeature.value().model.rawValue
        return QuickAnswersModel(rawValue: rawValue) ?? .exa
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
