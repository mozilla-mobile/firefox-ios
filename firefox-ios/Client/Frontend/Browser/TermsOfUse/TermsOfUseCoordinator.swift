// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common

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
    private let defaults: UserDefaultsInterface
    private let daysSinceDismissedTerms = 5

    init(windowUUID: WindowUUID,
         router: Router,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.defaults = userDefaults
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
        if !isFeatureEnabled { return false }

        let hasAccepted = defaults.bool(forKey: TermsOfUseMiddleware.DefaultKeys.acceptedKey)
        if hasAccepted { return false }

        let didShowThisLaunch = store.state.screenState(
            TermsOfUseState.self,
            for: .termsOfUse,
            window: windowUUID
        )?.didShowThisLaunch ?? false

        if didShowThisLaunch {
            if let dismissedWithoutAcceptDate = defaults.object(forKey:
                    TermsOfUseMiddleware.DefaultKeys.dismissedWithoutAcceptDate) as? Date {
                let days = Calendar.current.dateComponents([.day], from: dismissedWithoutAcceptDate, to: Date()).day ?? 0
                if days >= daysSinceDismissedTerms {
                    return true
                }
            }
            return false
        }
        return true
    }
}
