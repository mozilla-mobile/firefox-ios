// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol SettingsCoordinatorDelegate: AnyObject {
    func openURLinNewTab(_ url: URL)
    func didFinishSettings(from coordinator: SettingsCoordinator)
}

class SettingsCoordinator: BaseCoordinator, SettingsDelegate, SettingsFlowDelegate {
    var settingsViewController: AppSettingsScreen
    private let wallpaperManager: WallpaperManagerInterface
    private let profile: Profile
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    weak var parentCoordinator: SettingsCoordinatorDelegate?

    init(router: Router,
         wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.wallpaperManager = wallpaperManager
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.settingsViewController = AppSettingsTableViewController(with: profile,
                                                                     and: tabManager)
        super.init(router: router)

        router.setRootViewController(settingsViewController)
        settingsViewController.settingsDelegate = self
        settingsViewController.parentCoordinator = self
    }

    func start(with settingsSection: Route.SettingsSection) {
        // We might already know the sub-settings page we want to show, but in some case we don't and
        // the flow decision needs to be figured out by the view controller
        if let viewController = getSettingsViewController(settingsSection: settingsSection) {
            router.push(viewController)
        } else {
            settingsViewController.handle(route: settingsSection)
        }
    }

    override func handle(route: Route) -> Bool {
        switch route {
        case let .settings(section):
            start(with: section)
            return true
        default:
            return false
        }
    }

    private func getSettingsViewController(settingsSection section: Route.SettingsSection) -> UIViewController? {
        switch section {
        case .newTab:
            let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
            viewController.profile = profile
            return viewController

        case .homePage:
            let viewController = HomePageSettingViewController(prefs: profile.prefs)
            viewController.profile = profile
            return viewController

        case .mailto:
            let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
            return viewController

        case .search:
            let viewController = SearchSettingsTableViewController(profile: profile)
            return viewController

        case .clearPrivateData:
            let viewController = ClearPrivateDataTableViewController()
            viewController.profile = profile
            viewController.tabManager = tabManager
            return viewController

        case .fxa:
            let fxaParams = FxALaunchParams(entrypoint: .fxaDeepLinkSetting, query: [:])
            let viewController = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
                fxaParams,
                flowType: .emailLoginFlow,
                referringPage: .settings,
                profile: profile
            )
            return viewController

        case .theme:
            return ThemeSettingsController()

        case .wallpaper:
            if wallpaperManager.canSettingsBeShown {
                let viewModel = WallpaperSettingsViewModel(
                    wallpaperManager: wallpaperManager,
                    tabManager: tabManager,
                    theme: themeManager.currentTheme
                )
                let wallpaperVC = WallpaperSettingsViewController(viewModel: viewModel)
                return wallpaperVC
            } else {
                return nil
            }

        case .contentBlocker:
            let contentBlockerVC = ContentBlockerSettingViewController(prefs: profile.prefs)
            contentBlockerVC.profile = profile
            contentBlockerVC.tabManager = tabManager
            return contentBlockerVC

        case .tabs:
            return TabsSettingsViewController()

        case .toolbar:
            let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs)
            return SearchBarSettingsViewController(viewModel: viewModel)

        case .topSites:
            return TopSitesSettingsViewController()

        case .creditCard, .password:
            return nil // Needs authentication, decision handled by VC

        case .general:
            return nil // Return nil since we're already at the general page
        }
    }

    // MARK: - SettingsDelegate
    func settingsOpenURLInNewTab(_ url: URL) {
        parentCoordinator?.openURLinNewTab(url)
    }

    func didFinish() {
        parentCoordinator?.didFinishSettings(from: self)
    }

    // MARK: - SettingsFlowDelegate
    func showDevicePassCode() {
        let passcodeViewController = DevicePasscodeRequiredViewController()
        passcodeViewController.profile = profile
        router.push(passcodeViewController)
    }

    func showCreditCardSettings() {
        let viewModel = CreditCardSettingsViewModel(profile: profile)
        let creditCardViewController = CreditCardSettingsViewController(creditCardViewModel: viewModel)
        router.push(creditCardViewController)
    }

    func showExperiments() {
        let experimentsViewController = ExperimentsViewController()
        router.push(experimentsViewController)
    }

    // TODO: Move the both show password methods into it's own coordinator
    func showPasswordList() {
        let navigationHandler: (_ url: URL?) -> Void = { url in
            guard let url = url else { return }
            self.settingsOpenURLInNewTab(url)
            self.didFinish()
        }

        let viewController = LoginListViewController(
            profile: profile,
            webpageNavigationHandler: navigationHandler
        )
        viewController.settingsDelegate = self
        router.push(viewController)
    }

    func showPasswordOnboarding() {
        
    }

    func didFinishShowingSettings() {
        didFinish()
    }
}
