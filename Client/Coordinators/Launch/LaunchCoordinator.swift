// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

// Manages different types of onboarding that gets shown at the launch of the application
class LaunchCoordinator: BaseCoordinator, OpenURLDelegate {
    private let profile: Profile
    private let logger: Logger
    private let isIphone: Bool
    weak var parentCoordinator: OpenURLDelegate?

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
        self.isIphone = isIphone
        super.init(router: router)
    }

    func start(with launchType: LaunchType, onCompletion: @escaping () -> Void) {
        print("Laurie - LaunchCoordinator init")
        let isFullScreen = launchType.isFullScreenAvailable(isIphone: isIphone)
        switch launchType {
        case .intro(let manager):
            presentIntroOnboarding(with: manager, isFullScreen: isFullScreen, onCompletion: onCompletion)
        case .update(let viewModel):
            presentUpdateOnboarding(with: viewModel, isFullScreen: isFullScreen, onCompletion: onCompletion)
        case .defaultBrowser:
            presentDefaultBrowserOnboarding(onCompletion: onCompletion)
        case .survey(let manager):
            presentSurvey(with: manager, onCompletion: onCompletion)
        }
    }

    deinit {
        print("Laurie - LaunchCoordinator deinit")
    }

    // MARK: - Intro
    private func presentIntroOnboarding(with manager: IntroScreenManager,
                                        isFullScreen: Bool,
                                        onCompletion: @escaping () -> Void) {
        let introViewModel = IntroViewModel(introScreenManager: manager)
        let introViewController = IntroViewController(viewModel: introViewModel,
                                                      profile: profile)
        introViewController.didFinishFlow = {
            onCompletion()
        }

        if isFullScreen {
            introViewController.modalPresentationStyle = .fullScreen
            router.setRootViewController(introViewController, hideBar: true)
        } else {
            introViewController.preferredContentSize = CGSize(
                width: ViewControllerConsts.PreferredSize.IntroViewController.width,
                height: ViewControllerConsts.PreferredSize.IntroViewController.height)
            introViewController.modalPresentationStyle = .formSheet
            router.present(introViewController, animated: true)
        }
    }

    // MARK: - Update
    private func presentUpdateOnboarding(with updateViewModel: UpdateViewModel,
                                         isFullScreen: Bool,
                                         onCompletion: @escaping () -> Void) {
        let updateViewController = UpdateViewController(viewModel: updateViewModel)
        updateViewController.didFinishFlow = {
            onCompletion()
        }

        if isFullScreen {
            updateViewController.modalPresentationStyle = .fullScreen
            router.setRootViewController(updateViewController, hideBar: true)
        } else {
            updateViewController.preferredContentSize = CGSize(
                width: ViewControllerConsts.PreferredSize.UpdateViewController.width,
                height: ViewControllerConsts.PreferredSize.UpdateViewController.height)
            updateViewController.modalPresentationStyle = .formSheet
            router.present(updateViewController)
        }
    }

    // MARK: - Default Browser
    func presentDefaultBrowserOnboarding(onCompletion: @escaping () -> Void) {
        let defaultOnboardingViewController = DefaultBrowserOnboardingViewController()
        defaultOnboardingViewController.viewModel.goToSettings = {
            onCompletion()
        }

        defaultOnboardingViewController.viewModel.didAskToDismissView = {
            onCompletion()
        }

        defaultOnboardingViewController.preferredContentSize = CGSize(
            width: ViewControllerConsts.PreferredSize.DBOnboardingViewController.width,
            height: ViewControllerConsts.PreferredSize.DBOnboardingViewController.height)
        defaultOnboardingViewController.modalPresentationStyle = .formSheet
        router.present(defaultOnboardingViewController)
    }

    // MARK: - Survey
    func presentSurvey(with manager: SurveySurfaceManager, onCompletion: @escaping () -> Void) {
        guard let surveySurface = manager.getSurveySurface() else {
            logger.log("Tried presenting survey but no surface was found", level: .warning, category: .lifecycle)
            onCompletion()
            return
        }
        surveySurface.modalPresentationStyle = .fullScreen
        manager.openURLDelegate = self
        manager.dismissClosure = {
            onCompletion()
        }

        router.setRootViewController(surveySurface, hideBar: true)
    }

    // MARK: OpenURLDelegate

    func didRequestToOpenInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        parentCoordinator?.didRequestToOpenInNewTab(url: url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }
}
