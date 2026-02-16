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
    private let nimbus: FxNimbus

    private var presentedVC: TermsOfUseViewController?
    private let prefs: Prefs
    private let hoursSinceDismissedTerms = 120 // 120 hours (5 days)
    private let debugMinutesSinceDismissed = 1 // 1 minute used for testing
    private let experimentsTracking: ToUExperimentsTracking

    private var maxRemindersCount: Int {
        return nimbus.features.touFeature.value().maxRemindersCount
    }

    private var enableDragToDismiss: Bool {
        return nimbus.features.touFeature.value().enableDragToDismiss
    }

    private var contentOption: TermsOfUseContentOption {
        let nimbusValue = nimbus.features.touFeature.value().contentOption
        return TermsOfUseContentOption(rawValue: nimbusValue.rawValue) ?? .value0
    }

    init(windowUUID: WindowUUID,
         router: Router,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         prefs: Prefs,
         experimentsTracking: ToUExperimentsTracking,
         nimbus: FxNimbus = FxNimbus.shared) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.prefs = prefs
        self.nimbus = nimbus
        self.experimentsTracking = experimentsTracking
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
            notificationCenter: notificationCenter,
            enableDragToDismiss: enableDragToDismiss,
            contentOption: contentOption
        )
        vc.coordinator = self
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.presentedVC = vc

        router.present(vc, animated: true)
    }

    func dismissTermsFlow() {
        router.dismiss(animated: true) { [weak self] in
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
        linkVC.modalPresentationStyle = .pageSheet
        linkVC.modalTransitionStyle = .coverVertical
        presentedVC?.present(linkVC, animated: true)
    }

    func shouldShowTermsOfUse(context: TriggerContext = .appLaunch) -> Bool {
        // 1. Feature must be enabled
        guard featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly) else { return false }

        // 2. If user has already accepted, never show again
        let hasAcceptedTermsOfUse = prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
        guard !hasAcceptedTermsOfUse else { return false }

        // If experiment configuration changed, reset dismissal state
        experimentsTracking.resetToUDataIfNeeded()

        // 3. Check if this is the first time it is shown
        // Always show first time - it is not a reminder
        let hasShownFirstTime = prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? false
        guard hasShownFirstTime else { return true }

        // 4. Check reminders count limit from Nimbus
        let currentRemindersCount = prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0
        guard currentRemindersCount < maxRemindersCount else { return false }

        // 5. Check if user dismissed and timeout period expired
        guard let dismissedTimestamp = prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) else {
            // No dismissal record - user hasn't explicitly dismissed, so show it
            return true
        }

        let dismissedDate = Date.fromTimestamp(dismissedTimestamp)

        // 6. After timeout period show on any trigger context
        return hasTimeoutPeriodElapsed(since: dismissedDate)
    }

    /// Checks if the timeout period has elapsed since the given dismissal date
    /// Uses debug setting override for testing purposes (1 minute vs 120 hours)
    private func hasTimeoutPeriodElapsed(since dismissedDate: Date) -> Bool {
        let rawValue = UserDefaults.standard.integer(forKey: PrefsKeys.FasterTermsOfUseTimeoutOverride)
        let option = TermsOfUseTimeoutOption(rawValue: rawValue) ?? .normal

        switch option {
        case .normal:
            let hoursSinceDismissal = Calendar.current.dateComponents(
                [.hour],
                from: dismissedDate,
                to: Date()
            ).hour ?? 0
            return hoursSinceDismissal >= hoursSinceDismissedTerms

        case .oneMinute:
            let minutesSinceDismissal = Calendar.current.dateComponents(
                [.minute],
                from: dismissedDate,
                to: Date()
            ).minute ?? 0
            return minutesSinceDismissal >= debugMinutesSinceDismissed
        }
    }
}
