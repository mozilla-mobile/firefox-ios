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

class SettingsCoordinator: BaseCoordinator, SettingsDelegate {
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
        super.init(router: router)
    }

    func start(with settingsSection: Route.SettingsSection) {
        guard let viewController = getSettingsViewController(settingsSection: settingsSection) else { return }
        router.push(viewController)
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

        default:
            // FXIOS-6483: For cases that are not yet handled we show the main settings page
            return nil
        }
    }

    // MARK: - SettingsDelegate
    func settingsOpenURLInNewTab(_ url: URL) {
        parentCoordinator?.openURLinNewTab(url)
    }

    func didFinish() {
        parentCoordinator?.didFinishSettings(from: self)
    }
}
