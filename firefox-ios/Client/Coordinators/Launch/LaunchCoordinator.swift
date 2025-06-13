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
    func didFinishTermsOfService(from coordinator: LaunchCoordinator)
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

    init(router: Router,
         windowUUID: WindowUUID,
         profile: Profile = AppContainer.shared.resolve(),
         isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone) {
        self.profile = profile
        self.isIphone = isIphone
        self.windowUUID = windowUUID
        super.init(router: router)
    }

    func start(with launchType: LaunchType) {
        let isFullScreen = launchType.isFullScreenAvailable(isIphone: isIphone)
        switch launchType {
        case .termsOfService(let manager):
            if manager.isModernOnboardingEnabled {
                presentModernTermsOfService(with: manager, isFullScreen: isFullScreen)
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

    // MARK: - Terms of Service
    private func presentModernTermsOfService(
        with manager: TermsOfServiceManager,
        isFullScreen: Bool
    ) {
        TermsOfServiceTelemetry().termsOfServiceScreenDisplayed()

        let termsOfServiceLink = String(format: .Onboarding.Modern.TermsOfService.TermsOfUseLink, AppName.shortName.rawValue)
        let termsOfServiceAgreement = String(
            format: .Onboarding.Modern.TermsOfService.TermsOfServiceAgreement,
            termsOfServiceLink
        )

        let privacyNoticeLink = String.Onboarding.TermsOfService.PrivacyNoticeLink
        let privacyAgreement = String(
            format: .Onboarding.Modern.TermsOfService.PrivacyNoticeAgreement,
            AppName.shortName.rawValue,
            privacyNoticeLink
        )

        let manageLink = String.Onboarding.TermsOfService.ManageLink
        let manageAgreement = String(
            format: String.Onboarding.Modern.TermsOfService.ManagePreferenceAgreement,
            AppName.shortName.rawValue,
            MozillaName.shortName.rawValue,
            manageLink
        )

        let viewModel = TosFlowViewModel(
            configuration: OnboardingKitCardInfoModel(
                cardType: .basic,
                name: "tos",
                order: 20,
                title: .Onboarding.Modern.TermsOfService.Title,
                body: .Onboarding.Modern.TermsOfService.Subtitle,
                buttons: OnboardingKit.OnboardingButtons(
                    primary: OnboardingKit.OnboardingButtonInfoModel(
                        title: .Onboarding.Modern.TermsOfService.AgreementButtonTitleV3,
                        action: OnboardingActions.syncSignIn
                    )
                ),
                multipleChoiceButtons: [],
                onboardingType: .freshInstall,
                a11yIdRoot: AccessibilityIdentifiers.TermsOfService.root,
                imageID: ImageIdentifiers.homeHeaderLogoBall,
                embededLinkText: [
                    EmbeddedLink(
                        fullText: termsOfServiceAgreement,
                        linkText: termsOfServiceLink,
                        action: .openTermsOfService
                    ),
                    EmbeddedLink(
                        fullText: privacyAgreement,
                        linkText: privacyNoticeLink,
                        action: .openPrivacyNotice
                    ),
                    EmbeddedLink(
                        fullText: manageAgreement,
                        linkText: manageLink,
                        action: .openManageSettings
                    )
                ]
            ),
            onTermsOfServiceTap: { [weak self] in
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
                manager.setAccepted()
                TermsOfServiceTelemetry().termsOfServiceAcceptButtonTapped()

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

        let view = TermsOfServiceView(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager,
            onEmbededLinkAction: { _ in }
        )

        let viewController = UIHostingController(rootView: view)
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        router.present(viewController, animated: false)
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
            manager.setAccepted()
            TermsOfServiceTelemetry().termsOfServiceAcceptButtonTapped()

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

    private lazy var onboardingService: OnboardingService = {
        OnboardingService(
            windowUUID: windowUUID,
            profile: profile,
            themeManager: themeManager,
            delegate: self,
            navigationDelegate: self,
            qrCodeNavigationHandler: self
        )
    }()

    // MARK: - Intro
    private func presentModernIntroOnboarding(with manager: IntroScreenManagerProtocol,
                                              isFullScreen: Bool) {
        let onboardingModel = NimbusOnboardingKitFeatureLayer().getOnboardingModel(for: .freshInstall)
        let activityEventHelper = ActivityEventHelper()
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)

        let view = OnboardingView<OnboardingKitCardInfoModel>(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: OnboardingFlowViewModel(
                onboardingCards: onboardingModel.cards,
                onActionTap: { [weak self] action, cardName, completion in
                    guard let self = self else { return }
                    onboardingService.handleAction(
                        action,
                        from: cardName,
                        cards: onboardingModel.cards,
                        with: activityEventHelper,
                        completion: completion
                    )
                },
                onComplete: { [weak self] currentCardName in
                    guard let self = self else { return }
                    manager.didSeeIntroScreen()
                    SearchBarLocationSaver().saveUserSearchBarLocation(profile: profile)
                    telemetryUtility.sendDismissOnboardingTelemetry(from: currentCardName)

                    parentCoordinator?.didFinishLaunch(from: self)
                }
            )
        )
        let hostingController = UIHostingController(rootView: view)
        if isFullScreen {
            hostingController.modalPresentationStyle = .fullScreen
            router.present(hostingController, animated: false)
        } else {
            hostingController.preferredContentSize = CGSize(
                width: ViewControllerConsts.PreferredSize.IntroViewController.width,
                height: ViewControllerConsts.PreferredSize.IntroViewController.height)
            hostingController.modalPresentationStyle = .formSheet

            if !onboardingModel.isDismissable {
                hostingController.isModalInPresentation = true
            }

            router.present(hostingController, animated: true) {}
        }
    }

    // MARK: - Intro
    private func presentIntroOnboarding(with manager: IntroScreenManagerProtocol,
                                        isFullScreen: Bool) {
        let onboardingModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)

        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
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
        } else {
            introViewController.preferredContentSize = CGSize(
                width: ViewControllerConsts.PreferredSize.IntroViewController.width,
                height: ViewControllerConsts.PreferredSize.IntroViewController.height)
            introViewController.modalPresentationStyle = .formSheet
            // Disables dismissing the view by tapping outside the view, based on
            // Nimbus's configuration
            if !introViewModel.isDismissable {
                introViewController.isModalInPresentation = true
            }
            router.present(introViewController, animated: true) {
                introViewController.closeOnboarding()
            }
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
            if !updateViewModel.isDismissable {
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
