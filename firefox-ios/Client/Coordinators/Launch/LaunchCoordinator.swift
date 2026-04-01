// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import OnboardingKit
import SwiftUI
import ComponentLibrary

protocol LaunchCoordinatorDelegate: AnyObject {
    @MainActor
    func didFinishTermsOfService(from coordinator: LaunchCoordinator)

    @MainActor
    func didFinishLaunch(from coordinator: LaunchCoordinator)
}

// Manages different types of onboarding that gets shown at the launch of the application
final class LaunchCoordinator: BaseCoordinator,
                               SurveySurfaceViewControllerDelegate,
                               QRCodeNavigationHandler,
                               ParentCoordinatorDelegate,
                               OnboardingNavigationDelegate,
                               OnboardingServiceDelegate {
    private let profile: Profile
    private let isIphone: Bool
    let windowUUID: WindowUUID
    let themeManager: ThemeManager = AppContainer.shared.resolve()
    weak var parentCoordinator: LaunchCoordinatorDelegate?
    private var onboardingService: OnboardingService?

    init(router: Router,
         windowUUID: WindowUUID,
         profile: Profile = AppContainer.shared.resolve(),
         isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone) {
        self.profile = profile
        self.isIphone = isIphone
        self.windowUUID = windowUUID
        super.init(router: router)
    }

    @MainActor
    func start(with launchType: LaunchType) {
        let isFullScreen = launchType.isFullScreenAvailable(isIphone: isIphone)
        switch launchType {
        case .termsOfService(let manager):
            if manager.isModernOnboardingEnabled {
                presentModernTermsOfUse(with: manager, isFullScreen: isFullScreen)
            } else {
                presentTermsOfService(with: manager, isFullScreen: isFullScreen)
            }
        case .intro(let manager):
            if manager.isModernOnboardingEnabled {
                presentModernIntroOnboarding(with: manager, isFullScreen: isFullScreen)
            } else {
                presentIntroOnboarding(with: manager, isFullScreen: isFullScreen)
            }
        case .update(let viewModel):
            presentUpdateOnboarding(with: viewModel, isFullScreen: isFullScreen)
        case .defaultBrowser:
            presentDefaultBrowserOnboarding()
        case .survey(let manager):
            presentSurvey(with: manager)
        }
    }

    // MARK: - Terms of Use
    private func presentModernTermsOfUse(
        with manager: TermsOfServiceManager,
        isFullScreen: Bool
    ) {
        TermsOfServiceTelemetry().termsOfServiceScreenDisplayed()

        // Get the onboarding variant from IntroScreenManager since ToS is shown before intro
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let onboardingKitVariant = introManager.onboardingKitVariant

        let viewModel = TermsOfUseFlowViewModel(
            configuration: TermsOfServiceManager.brandRefreshTermsOfUseConfiguration,
            variant: onboardingKitVariant,
            onTermsOfUseTap: { [weak self] in
                guard let self = self else { return }
                TermsOfServiceTelemetry().termsOfServiceLinkTapped()
                presentLink(with: URL(string: Links.termsOfService))
            },
            onPrivacyNoticeTap: { [weak self] in
                guard let self = self else { return }
                TermsOfServiceTelemetry().termsOfServicePrivacyNoticeLinkTapped()
                presentLink(with: URL(string: Links.privacyNotice))
            },
            onManageSettingsTap: { [weak self] in
                guard let self = self else { return }
                TermsOfServiceTelemetry().termsOfServiceManageLinkTapped()
                let managePreferencesVC = PrivacyPreferencesViewController(profile: profile, windowUUID: windowUUID)
                if UIDevice.current.userInterfaceIdiom != .phone {
                    managePreferencesVC.modalPresentationStyle = .formSheet
                }
                router.navigationController.presentedViewController?.present(managePreferencesVC, animated: true)
            },
            onComplete: { [weak self] in
                guard let self = self else { return }
                let acceptedDate = Date()
                manager.setAccepted(acceptedDate: acceptedDate)
                TermsOfServiceTelemetry().termsOfServiceAcceptButtonTapped(acceptedDate: acceptedDate)

                let sendTechnicalData = profile.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true
                let sendStudies = profile.prefs.boolForKey(AppConstants.prefStudiesToggle) ?? true
                manager.shouldSendTechnicalData(telemetryValue: sendTechnicalData, studiesValue: sendStudies)
                self.profile.prefs.setBool(sendTechnicalData, forKey: AppConstants.prefSendUsageData)

                let sendCrashReports = profile.prefs.boolForKey(AppConstants.prefSendCrashReports) ?? true
                self.profile.prefs.setBool(sendCrashReports, forKey: AppConstants.prefSendCrashReports)
                self.logger.setup(sendCrashReports: sendCrashReports)

                TelemetryWrapper.shared.setup(profile: profile)
                TelemetryWrapper.shared.recordStartUpTelemetry()

                self.parentCoordinator?.didFinishTermsOfService(from: self)
            }
        )

        let view = TermsOfUseView(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager
        )

        let viewController = PortraitOnlyHostingController(rootView: view)
        // `.overFullScreen` is required to display the underlying view controller beneath the presented one,
        // and to prevent a white strip glitch caused by synchronization issues between SwiftUI and UIKit.
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        viewController.view.backgroundColor = .clear

        router.present(viewController, animated: true)
    }

    private func presentLink(with url: URL?) {
        guard let url else { return }
        let presentLinkVC = PrivacyPolicyViewController(url: url, windowUUID: windowUUID)

        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: #selector(dismissPresentedLinkVC))
        buttonItem.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfService.doneButton

        presentLinkVC.navigationItem.rightBarButtonItem = buttonItem
        let controller = DismissableNavigationViewController(rootViewController: presentLinkVC)
        router.navigationController.presentedViewController?.present(controller, animated: true)
    }

    @objc
    private func dismissPresentedLinkVC() {
        router.navigationController.presentedViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Terms of Service
    private func presentTermsOfService(with manager: TermsOfServiceManager,
                                       isFullScreen: Bool) {
        TermsOfServiceTelemetry().termsOfServiceScreenDisplayed()
        let viewController = TermsOfServiceViewController(profile: profile, windowUUID: windowUUID)
        viewController.didFinishFlow = { [weak self] in
            guard let self = self else { return }
            let acceptedDate = Date()
            manager.setAccepted(acceptedDate: acceptedDate)
            TermsOfServiceTelemetry().termsOfServiceAcceptButtonTapped(acceptedDate: acceptedDate)

            let sendTechnicalData = profile.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true
            let sendStudies = profile.prefs.boolForKey(AppConstants.prefStudiesToggle) ?? true
            manager.shouldSendTechnicalData(telemetryValue: sendTechnicalData, studiesValue: sendStudies)
            self.profile.prefs.setBool(sendTechnicalData, forKey: AppConstants.prefSendUsageData)

            let sendCrashReports = profile.prefs.boolForKey(AppConstants.prefSendCrashReports) ?? true
            self.profile.prefs.setBool(sendCrashReports, forKey: AppConstants.prefSendCrashReports)
            self.logger.setup(sendCrashReports: sendCrashReports)

            TelemetryWrapper.shared.setup(profile: profile)
            TelemetryWrapper.shared.recordStartUpTelemetry()

            self.parentCoordinator?.didFinishTermsOfService(from: self)
        }
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        router.present(viewController, animated: false)
    }

    // MARK: - Intro
    @MainActor
    private func presentModernIntroOnboarding(with manager: IntroScreenManagerProtocol,
                                              isFullScreen: Bool) {
        let onboardingModel = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: manager.onboardingVariant,
            isDefaultBrowser: DefaultBrowserUtility().isDefaultBrowser,
            isIpad: UIDevice.current.userInterfaceIdiom == .pad
        ).getOnboardingModel(
            for: .freshInstall
        )
        let activityEventHelper = ActivityEventHelper()
        let onboardingReason: OnboardingReason = manager.shouldShowIntroScreen ? .newUser : .showTour
        let telemetryUtility = OnboardingTelemetryUtility(
            with: onboardingModel,
            onboardingVariant: manager.onboardingVariant,
            onboardingReason: onboardingReason
        )

        // Create onboardingService and store it directly - don't create local variable
        self.onboardingService = OnboardingService(
            windowUUID: windowUUID,
            profile: profile,
            themeManager: themeManager,
            delegate: self,
            navigationDelegate: self,
            qrCodeNavigationHandler: self
        )
        self.onboardingService?.telemetryUtility = telemetryUtility

        let onboardingKitVariant = manager.onboardingKitVariant

        let flowViewModel = OnboardingFlowViewModel<OnboardingKitCardInfoModel>(
            onboardingCards: onboardingModel.cards,
            skipText: .Onboarding.LaterAction,
            variant: onboardingKitVariant,
            onActionTap: { [weak self] action, cardName, completion in
                guard let onboardingService = self?.onboardingService else { return }
                onboardingService.handleAction(
                    action,
                    from: cardName,
                    cards: onboardingModel.cards,
                    with: activityEventHelper,
                    completion: completion
                )
            },
            onMultipleChoiceActionTap: { [weak self] action, cardName in
                guard let onboardingService = self?.onboardingService else { return }
                onboardingService.handleMultipleChoiceAction(
                    action,
                    from: cardName
                )
            },
            onComplete: { [weak self] currentCardName, outcome in
                guard let self = self else { return }
                if outcome == .skipped {
                    telemetryUtility.sendDismissOnboardingTelemetry(from: currentCardName)
                }
                telemetryUtility.sendOnboardingDismissedTelemetry(outcome: outcome)
                manager.didSeeIntroScreen()
                SearchBarLocationSaver().saveUserSearchBarLocation(profile: profile)
                self.onboardingService = nil
                parentCoordinator?.didFinishLaunch(from: self)
            }
        )

        flowViewModel.onCardView = { cardName in
            telemetryUtility.sendCardViewTelemetry(from: cardName)
        }

        flowViewModel.onButtonTap = { cardName, action, isPrimary in
            telemetryUtility.sendButtonActionTelemetry(
                from: cardName,
                with: action,
                and: isPrimary
            )
        }

        flowViewModel.onMultipleChoiceTap = { cardName, action in
            telemetryUtility.sendMultipleChoiceButtonActionTelemetry(
                from: cardName,
                with: action
            )
        }

        let view = OnboardingView<OnboardingKitCardInfoModel>(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: flowViewModel,
            pageControlAccessibilityId: AccessibilityIdentifiers.Onboarding.pageControl,
            closeButtonAccessibilityId: AccessibilityIdentifiers.Onboarding.closeButton
        )

        let hostingController = PortraitOnlyHostingController(rootView: view)
        // `.overFullScreen` is required to display the underlying view controller beneath the presented one,
        // and to prevent a white strip glitch caused by synchronization issues between SwiftUI and UIKit.
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.view.backgroundColor = .clear

        router.present(hostingController, animated: true)
        telemetryUtility.sendOnboardingShownTelemetry()
    }

    // MARK: - Intro
    private func presentIntroOnboarding(with manager: IntroScreenManagerProtocol,
                                        isFullScreen: Bool) {
        let onboardingModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
        let onboardingReason: OnboardingReason = manager.shouldShowIntroScreen ? .newUser : .showTour

        let telemetryUtility = OnboardingTelemetryUtility(
            with: onboardingModel,
            onboardingReason: onboardingReason
        )
        let introViewModel = IntroViewModel(introScreenManager: manager,
                                            profile: profile,
                                            model: onboardingModel,
                                            telemetryUtility: telemetryUtility)
        let introViewController = IntroViewController(viewModel: introViewModel, windowUUID: windowUUID)
        introViewController.qrCodeNavigationHandler = self
        introViewController.didFinishFlow = { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.didFinishLaunch(from: self)
        }

        if isFullScreen {
            introViewController.modalPresentationStyle = .fullScreen
            router.present(introViewController, animated: false)
            telemetryUtility.sendOnboardingShownTelemetry()
        } else {
            introViewController.preferredContentSize = CGSize(
                width: ViewControllerConsts.PreferredSize.IntroViewController.width,
                height: ViewControllerConsts.PreferredSize.IntroViewController.height)
            introViewController.modalPresentationStyle = .formSheet
            // Disables dismissing the view by tapping outside the view, based on
            // Nimbus's configuration
            if !introViewModel.isDismissible {
                introViewController.isModalInPresentation = true
            }
            router.present(introViewController, animated: true) {
                introViewController.closeOnboarding()
            }
            telemetryUtility.sendOnboardingShownTelemetry()
        }
    }

    // MARK: - Update
    private func presentUpdateOnboarding(with updateViewModel: UpdateViewModel,
                                         isFullScreen: Bool) {
        let updateViewController = UpdateViewController(viewModel: updateViewModel, windowUUID: windowUUID)
        updateViewController.qrCodeNavigationHandler = self
        updateViewController.didFinishFlow = { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.didFinishLaunch(from: self)
        }

        if isFullScreen {
            updateViewController.modalPresentationStyle = .fullScreen
            router.present(updateViewController, animated: false)
        } else {
            updateViewController.preferredContentSize = CGSize(
                width: ViewControllerConsts.PreferredSize.UpdateViewController.width,
                height: ViewControllerConsts.PreferredSize.UpdateViewController.height)
            updateViewController.modalPresentationStyle = .formSheet
            // Nimbus's configuration
            if !updateViewModel.isDismissible {
                updateViewController.isModalInPresentation = true
            }
            router.present(updateViewController)
        }
    }

    // MARK: - Default Browser
    func presentDefaultBrowserOnboarding() {
        let defaultOnboardingViewController = DefaultBrowserOnboardingViewController(windowUUID: windowUUID)
        defaultOnboardingViewController.viewModel.goToSettings = { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.didFinishLaunch(from: self)
        }

        defaultOnboardingViewController.viewModel.didAskToDismissView = { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.didFinishLaunch(from: self)
        }

        defaultOnboardingViewController.preferredContentSize = CGSize(
            width: ViewControllerConsts.PreferredSize.DBOnboardingViewController.width,
            height: ViewControllerConsts.PreferredSize.DBOnboardingViewController.height)
        let isiPhone = UIDevice.current.userInterfaceIdiom == .phone
        defaultOnboardingViewController.modalPresentationStyle = isiPhone ? .fullScreen : .formSheet
        router.present(defaultOnboardingViewController)
    }

    // MARK: - Survey
    func presentSurvey(with manager: SurveySurfaceManager) {
        guard let surveySurface = manager.getSurveySurface() else {
            logger.log("Tried presenting survey but no surface was found", level: .warning, category: .lifecycle)
            parentCoordinator?.didFinishLaunch(from: self)
            return
        }
        surveySurface.modalPresentationStyle = .fullScreen
        surveySurface.delegate = self
        router.present(surveySurface, animated: false)
    }

    // MARK: - QRCodeNavigationHandler

    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController?) {
        var coordinator: QRCodeCoordinator
        if let qrCodeCoordinator = childCoordinators.first(where: { $0 is QRCodeCoordinator }) as? QRCodeCoordinator {
            coordinator = qrCodeCoordinator
        } else {
            if rootNavigationController != nil {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: DefaultRouter(navigationController: rootNavigationController!)
                )
            } else {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: router
                )
            }
            add(child: coordinator)
        }
        coordinator.showQRCode(delegate: delegate)
    }

    // MARK: - ParentCoordinatorDelegate

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }

    // MARK: - SurveySurfaceViewControllerDelegate
    func didFinish() {
        parentCoordinator?.didFinishLaunch(from: self)
    }

    // MARK: - OnboardingServiceDelegate
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        router.navigationController.presentedViewController?.dismiss(
            animated: animated,
            completion: completion
        )
    }

    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        router.navigationController.presentedViewController?.present(
            viewController,
            animated: true,
            completion: completion
        )
    }

    // MARK: - OnboardingNavigationDelegate
    func finishOnboardingFlow() {
        dismiss(animated: true, completion: nil)
    }
}
