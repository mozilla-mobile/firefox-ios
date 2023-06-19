// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol LaunchCoordinatorDelegate: AnyObject {
    func didFinishLaunch(from coordinator: LaunchCoordinator)
}

// Manages different types of onboarding that gets shown at the launch of the application
class LaunchCoordinator: BaseCoordinator, SurveySurfaceViewControllerDelegate {
    private let profile: Profile
    private let isIphone: Bool
    weak var parentCoordinator: LaunchCoordinatorDelegate?

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone) {
        self.profile = profile
        self.isIphone = isIphone
        super.init(router: router)
    }

    func start(with launchType: LaunchType) {
        let isFullScreen = launchType.isFullScreenAvailable(isIphone: isIphone)
        switch launchType {
        case .intro(let manager):
            presentIntroOnboarding(with: manager, isFullScreen: isFullScreen)
        case .update(let viewModel):
            presentUpdateOnboarding(with: viewModel, isFullScreen: isFullScreen)
        case .defaultBrowser:
            presentDefaultBrowserOnboarding()
        case .survey(let manager):
            presentSurvey(with: manager)
        }
    }

    // MARK: - Intro
    private func presentIntroOnboarding(with manager: IntroScreenManager,
                                        isFullScreen: Bool) {
        let onboardingModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        let introViewModel = IntroViewModel(introScreenManager: manager,
                                            profile: profile,
                                            model: onboardingModel,
                                            telemetryUtility: telemetryUtility)
        let introViewController = IntroViewController(viewModel: introViewModel)
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
            router.present(introViewController, animated: true)
        }
    }

    // MARK: - Update
    private func presentUpdateOnboarding(with updateViewModel: UpdateViewModel,
                                         isFullScreen: Bool) {
        let updateViewController = UpdateViewController(viewModel: updateViewModel)
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
        let defaultOnboardingViewController = DefaultBrowserOnboardingViewController()
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
        defaultOnboardingViewController.modalPresentationStyle = .formSheet
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

    // MARK: - SurveySurfaceViewControllerDelegate
    func didFinish() {
        parentCoordinator?.didFinishLaunch(from: self)
    }
}
