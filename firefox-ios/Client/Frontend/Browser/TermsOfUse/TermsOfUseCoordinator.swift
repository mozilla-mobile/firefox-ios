// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared

// TODO: FXIOS-12947 - Add tests for TermsOfUseCoordinator
@MainActor
protocol TermsOfUseCoordinatorDelegate: AnyObject {
    func dismissTermsFlow()
    func showTermsLink(url: URL)
}

@MainActor
final class TermsOfUseCoordinator: BaseCoordinator, TermsOfUseCoordinatorDelegate, FeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let notificationCenter: NotificationProtocol

    private var presentedVC: TermsOfUseViewController?
    private let prefs: Prefs
    private let daysSinceDismissedTerms = 5

    init(windowUUID: WindowUUID,
         router: Router,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         prefs: Prefs) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.prefs = prefs
        super.init(router: router)
    }

    func start() {
        guard shouldShowTermsOfUse() else {
            parentCoordinator?.didFinish(from: self)
            return
        }

        let vc = TermsOfUseViewController(
            themeManager: themeManager,
            windowUUID: windowUUID,
            notificationCenter: notificationCenter
        )
        vc.coordinator = self
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.presentedVC = vc

        router.present(vc, animated: true)
    }

    func dismissTermsFlow() {
        presentedVC?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.didFinish(from: self)
        }
    }

    func showTermsLink(url: URL) {
        let linkVC = TermsOfUseLinkViewController(
            url: url,
            windowUUID: windowUUID,
            themeManager: themeManager,
            notificationCenter: notificationCenter
        )
        presentedVC?.present(linkVC, animated: true)
    }

    func shouldShowTermsOfUse() -> Bool {
        let isFeatureEnabled = featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly)
        // 1. If feature is disabled, do not show.
        guard isFeatureEnabled else { return false }

        let hasAccepted = prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
        // 2. If user has accepted, do not show again.
        guard !hasAccepted else { return false }

        let didShowThisLaunch = store.state.screenState(
            TermsOfUseState.self,
            for: .termsOfUse,
            window: windowUUID
        )?.didShowThisLaunch ?? false

        // 3. If not shown this launch, show it.
        guard didShowThisLaunch else { return true }

        // 4. If shown this launch, show it if enough time has passed since dismissal.
        guard let dismissedTimestamp = prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate)
        else { return false }

        let dismissedWithoutAcceptDate = Date.fromTimestamp(dismissedTimestamp)
        let daysSinceDismissal = Calendar.current.dateComponents(
            [.day],
            from: dismissedWithoutAcceptDate,
            to: Date()
        ).day ?? 0

        return daysSinceDismissal >= daysSinceDismissedTerms
    }
}
