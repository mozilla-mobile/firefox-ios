// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared

enum TriggerContext {
    case appLaunch
    case homepageOpened
    case appBecameActive
}

@MainActor
protocol TermsOfUseDelegate: AnyObject {
    func showTermsOfUse(context: TriggerContext)
}

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
    private let hoursSinceDismissedTerms = 120 // 120 hours (5 days)

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

    func start(context: TriggerContext = .appLaunch) {
        guard shouldShowTermsOfUse(context: context) else {
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

    func shouldShowTermsOfUse(context: TriggerContext = .appLaunch) -> Bool {
        // 1. Feature must be enabled
        guard featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly) else { return false }

        // 2. If user has already accepted (onboarding or bottom sheet), never show again
        let hasAcceptedTermsOfUse = prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
        let hasAcceptedTermsOfService = prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == 1
        guard !hasAcceptedTermsOfUse && !hasAcceptedTermsOfService else { return false }

        // 3. Check if this is the first time it is shown
        // Show on fresh install or next app open for existing users
        let hasShownFirstTime = prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? false
        guard hasShownFirstTime else { return true }

        // 4. Check if user dismissed and 120 hours passed
        guard let dismissedTimestamp = prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) else {
            // Already shown but no dismissal record - don't show
            return false
        }

        let dismissedDate = Date.fromTimestamp(dismissedTimestamp)
        let hoursSinceDismissal = Calendar.current.dateComponents(
            [.hour],
            from: dismissedDate,
            to: Date()
        ).hour ?? 0

        // 5. After 120 hours: show on any trigger context
        return hoursSinceDismissal >= hoursSinceDismissedTerms
    }
}
