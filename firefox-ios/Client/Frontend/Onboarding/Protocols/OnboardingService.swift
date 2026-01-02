// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared
import ComponentLibrary
import OnboardingKit

@MainActor
final class OnboardingService: FeatureFlaggable {
    // MARK: - Properties
    private weak var delegate: OnboardingServiceDelegate?
    private weak var navigationDelegate: OnboardingNavigationDelegate?
    private weak var qrCodeNavigationHandler: QRCodeNavigationHandler?
    private var hasRegisteredForDefaultBrowserNotification = false
    private var userDefaults: UserDefaultsInterface
    private var windowUUID: WindowUUID
    private var profile: Profile
    private var introScreenManager: IntroScreenManagerProtocol?
    private var themeManager: ThemeManager
    private var hasSyncFlowStarted = false

    // MARK: - Injected Dependencies
    private let notificationManager: NotificationManagerProtocol
    private let defaultApplicationHelper: ApplicationHelper
    private let notificationCenter: NotificationProtocol
    private let searchBarLocationSaver: SearchBarLocationSaverProtocol
    weak var telemetryUtility: OnboardingTelemetryProtocol?

    init(
        userDefaults: UserDefaultsInterface = UserDefaults.standard,
        windowUUID: WindowUUID,
        profile: Profile,
        themeManager: ThemeManager,
        delegate: OnboardingServiceDelegate,
        navigationDelegate: OnboardingNavigationDelegate?,
        qrCodeNavigationHandler: QRCodeNavigationHandler?,
        notificationManager: NotificationManagerProtocol = NotificationManager(),
        defaultApplicationHelper: ApplicationHelper = DefaultApplicationHelper(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        searchBarLocationSaver: SearchBarLocationSaverProtocol = SearchBarLocationSaver()
    ) {
        self.delegate = delegate
        self.userDefaults = userDefaults
        self.windowUUID = windowUUID
        self.profile = profile
        self.themeManager = themeManager
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        self.navigationDelegate = navigationDelegate
        self.qrCodeNavigationHandler = qrCodeNavigationHandler
        self.notificationManager = notificationManager
        self.defaultApplicationHelper = defaultApplicationHelper
        self.notificationCenter = notificationCenter
        self.searchBarLocationSaver = searchBarLocationSaver
    }

    func handleAction(
        _ action: OnboardingActions,
        from cardName: String,
        cards: [OnboardingKitCardInfoModel],
        with activityEventHelper: ActivityEventHelper,
        completion: @Sendable @escaping @MainActor (
            Result<OnboardingFlowViewModel<OnboardingKitCardInfoModel>.TabAction, Error>
        ) -> Void
    ) {
        switch action {
        case .requestNotifications:
            handleRequestNotifications(from: cardName, with: activityEventHelper)
            completion(.success(.none))

        case .forwardOneCard:
            completion(.success(.advance(numberOfPages: 1)))

        case .forwardTwoCard:
            completion(.success(.advance(numberOfPages: 2)))

        case .forwardThreeCard:
            completion(.success(.advance(numberOfPages: 3)))

        case .syncSignIn:
            handleSyncSignIn(from: cardName, with: activityEventHelper, cards: cards) { [weak self] in
                if self?.hasSyncFlowStarted == true {
                    completion(.success(.advance(numberOfPages: 1)))
                }
            }

        case .setDefaultBrowser:
            handleSetDefaultBrowser(with: activityEventHelper)
            completion(.success(.none))

        case .openInstructionsPopup:
            guard let popupViewModel = cards
                .first(where: { $0.name == cardName })?
                .instructionsPopup
            else {
                completion(.failure(
                    NSError(
                        domain: "OnboardingServiceError",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Popup view model not found for card: \(cardName)"]
                    )
                ))
                return
            }
            handleOpenInstructionsPopup(
                from: popupViewModel
            ) {
                completion(.success(.advance(numberOfPages: 1)))
            }

        case .readPrivacyPolicy:
            guard let infoModel = cards
                .first(where: { $0.name == cardName }),
                  let url = infoModel.link?.url
            else {
                completion(.failure(
                    NSError(
                        domain: "OnboardingServiceError",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Privacy Policy URL not found for card: \(cardName)"]
                    )
                ))
                return
            }
            handleReadPrivacyPolicy(from: url) {
                completion(.success(.none))
            }

        case .openIosFxSettings:
            handleOpenIosFxSettings(from: cardName)
            completion(.success(.none))

        case .endOnboarding:
            handleEndOnboarding(with: activityEventHelper)
            completion(.success(.none))
        }
    }

    func handleMultipleChoiceAction(
        _ action: OnboardingMultipleChoiceAction,
        from cardName: String
    ) {
        switch action {
        case .themeDark:
            themeManager.setSystemTheme(isOn: false)
            themeManager.setManualTheme(to: .dark)
        case .themeLight:
            themeManager.setSystemTheme(isOn: false)
            themeManager.setManualTheme(to: .light)
        case .themeSystemDefault:
            themeManager.setSystemTheme(isOn: true)
        case .toolbarBottom:
            featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.bottom)
            let notificationObject = [PrefsKeys.FeatureFlags.SearchBarPosition: SearchBarPosition.bottom]
            notificationCenter.post(name: .SearchBarPositionDidChange, withObject: notificationObject)
        case .toolbarTop:
            featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.top)
            let notificationObject = [PrefsKeys.FeatureFlags.SearchBarPosition: SearchBarPosition.top]
            notificationCenter.post(name: .SearchBarPositionDidChange, withObject: notificationObject)
        }
    }

    // MARK: - Private Methods

    /// Checks if any card in the onboarding flow contains a request notifications action
    private func hasNotificationCard(in cards: [OnboardingKitCardInfoModel]) -> Bool {
        cards.contains {
            $0.buttons.primary.action == .requestNotifications
            || $0.buttons.secondary?.action == .requestNotifications
        }
    }

    private func handleRequestNotifications(from cardName: String, with activityEventHelper: ActivityEventHelper) {
        activityEventHelper.chosenOptions.insert(.askForNotificationPermission)
        activityEventHelper.updateOnboardingUserActivationEvent()
        askForNotificationPermission(from: cardName)
    }

    private func handleSyncSignIn(
        from cardName: String,
        with activityEventHelper: ActivityEventHelper,
        cards: [OnboardingKitCardInfoModel],
        completion: @escaping () -> Void
    ) {
        activityEventHelper.chosenOptions.insert(.syncSignIn)
        activityEventHelper.updateOnboardingUserActivationEvent()

        let fxaParams = FxALaunchParams(entrypoint: .introOnboarding, query: [:])
        presentSignToSync(
            with: fxaParams,
            profile: profile,
            notificationPermissionBehavior: !hasNotificationCard(in: cards) ? .request : .skip,
            completion: completion
        )
    }

    private func handleSetDefaultBrowser(with activityEventHelper: ActivityEventHelper) {
        activityEventHelper.chosenOptions.insert(.setAsDefaultBrowser)
        activityEventHelper.updateOnboardingUserActivationEvent()
        registerForNotification()
        telemetryUtility?.sendGoToSettingsButtonTappedTelemetry()
        defaultApplicationHelper.openSettings()
    }

    private func handleOpenInstructionsPopup(
        from popupViewModel: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>,
        completion: @Sendable @escaping @MainActor () -> Void
    ) {
        presentDefaultBrowserPopup(from: popupViewModel, completion: completion)
    }

    private func handleReadPrivacyPolicy(from url: URL, completion: @escaping () -> Void) {
        presentPrivacyPolicy(from: url, completion: completion)
    }

    private func handleOpenIosFxSettings(from cardName: String) {
        telemetryUtility?.sendGoToSettingsButtonTappedTelemetry()
        defaultApplicationHelper.openSettings()
    }

    private func handleEndOnboarding(with activityEventHelper: ActivityEventHelper) {
        introScreenManager?.didSeeIntroScreen()
        searchBarLocationSaver.saveUserSearchBarLocation(
            profile: profile,
            userInterfaceIdiom: UIDevice.current.userInterfaceIdiom
        )
        navigationDelegate?.finishOnboardingFlow()
    }

    private func askForNotificationPermission(from cardName: String) {
        notificationManager.requestAuthorization { [weak self] (granted: Bool, error: Error?) in
            guard error == nil, let self = self else { return }

            DispatchQueue.main.async {
                if granted {
                    if self.userDefaults.object(forKey: PrefsKeys.Notifications.SyncNotifications) == nil {
                        self.userDefaults.set(granted, forKey: PrefsKeys.Notifications.SyncNotifications)
                    }
                    if self.userDefaults.object(forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications) == nil {
                        self.userDefaults.set(granted, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
                    }
                    self.notificationCenter.post(name: .RegisterForPushNotifications)
                }
            }
        }
    }

    private func registerForNotification() {
        guard !hasRegisteredForDefaultBrowserNotification else { return }
        hasRegisteredForDefaultBrowserNotification = true
    }

    private func presentSignToSync(
        with params: FxALaunchParams,
        profile: Profile,
        notificationPermissionBehavior: NotificationPermissionRequestBehavior,
        completion: @escaping () -> Void
    ) {
        guard let delegate = delegate else { return }

        let signInVC = createSignInViewController(
            windowUUID: windowUUID,
            params: params,
            profile: profile,
            notificationPermissionBehavior: notificationPermissionBehavior,
            completion: completion
        )

        delegate.present(signInVC, animated: true, completion: nil)
    }

    private func presentDefaultBrowserPopup(
        from popupViewModel: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>,
        completion: @escaping @MainActor () -> Void
    ) {
        let popupVC = createDefaultBrowserPopupViewController(
            windowUUID: windowUUID,
            from: popupViewModel,
            completion: completion
        )

        delegate?.present(popupVC, animated: false, completion: nil)
    }

    private func presentPrivacyPolicy(from url: URL, completion: @escaping () -> Void) {
        guard let delegate = delegate else { return }
        let privacyVC = createPrivacyPolicyViewController(
            windowUUID: windowUUID,
            from: url,
            completion: completion
        )

        delegate.present(privacyVC, animated: true, completion: nil)
    }

    private func createSignInViewController(
        windowUUID: WindowUUID,
        params: FxALaunchParams,
        profile: Profile,
        notificationPermissionBehavior: NotificationPermissionRequestBehavior,
        completion: @escaping () -> Void
    ) -> UIViewController {
        // Reset sync flow started flag when creating a new sign-in view controller
        hasSyncFlowStarted = false

        let singInSyncVC = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
            params,
            flowType: .emailLoginFlow,
            referringPage: .onboarding,
            profile: profile,
            windowUUID: windowUUID,
            notificationPermissionBehavior: notificationPermissionBehavior
        )

        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: #selector(dismissSelector))
        if #available(iOS 26.0, *) {
            buttonItem.tintColor = themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary
        } else {
            buttonItem.tintColor = themeManager.getCurrentTheme(for: windowUUID).colors.actionPrimary
        }
        singInSyncVC.navigationItem.rightBarButtonItem = buttonItem
        (singInSyncVC as? FirefoxAccountSignInViewController)?.qrCodeNavigationHandler = qrCodeNavigationHandler
        (singInSyncVC as? FirefoxAccountSignInViewController)?.onSyncFlowStarted = { [weak self] in
            self?.hasSyncFlowStarted = true
        }

        let controller = DismissableNavigationViewController(rootViewController: singInSyncVC)
        controller.onViewDismissed = completion
        return controller
    }

    private func createDefaultBrowserPopupViewController(
        windowUUID: WindowUUID,
        from popupViewModel: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>,
        completion: @escaping () -> Void
    ) -> UIViewController {
        let instructionsVC = OnboardingInstructionPopupViewController(
            viewModel: popupViewModel,
            windowUUID: windowUUID,
            buttonTappedFinishFlow: { [weak self] in
                self?.telemetryUtility?.sendGoToSettingsButtonTappedTelemetry()
                completion()
            }
        )

        let bottomSheetVC = OnboardingBottomSheetViewController(windowUUID: windowUUID)
        bottomSheetVC.onDismiss = { [weak self] in
            self?.telemetryUtility?.sendDismissButtonTappedTelemetry()
        }
        bottomSheetVC.configure(
            closeButtonModel: CloseButtonViewModel(
                a11yLabel: .CloseButtonTitle,
                a11yIdentifier: AccessibilityIdentifiers.Onboarding.bottomSheetCloseButton
            ),
            child: instructionsVC
        )
        return bottomSheetVC
    }

    private func createPrivacyPolicyViewController(
        windowUUID: WindowUUID,
        from url: URL,
        completion: @escaping () -> Void
    ) -> UIViewController {
        let privacyPolicyVC = PrivacyPolicyViewController(url: url, windowUUID: windowUUID)
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: #selector(dismissSelector))

        privacyPolicyVC.navigationItem.rightBarButtonItem = buttonItem
        let controller = DismissableNavigationViewController(rootViewController: privacyPolicyVC)
        controller.onViewDismissed = completion
        return controller
    }

    @objc
    nonisolated private func dismissSelector() {
        ensureMainThread {
            self.delegate?.dismiss(animated: true, completion: nil)
        }
    }
}
