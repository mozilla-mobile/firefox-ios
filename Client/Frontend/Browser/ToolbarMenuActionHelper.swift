// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol ToolBarActionMenuDelegate: AnyObject {
    func openURLInNewTab(_ url: URL?, isPrivate: Bool)
    func presentViewController(viewController: UIViewController)
    func updateToolbarState()
}

typealias FXAClosureType = (params: FxALaunchParams?, flowType: FxAPageType, referringPage: ReferringPage)
struct ToolbarMenuActionHelper: PhotonActionSheetProtocol {

    private let prefs: Prefs
    let profile: Profile
    let tabManager: TabManager

    weak var settingsDelegate: SettingsDelegate?
    weak var delegate: ToolBarActionMenuDelegate?

    var showFXAClosure: (FXAClosureType) -> Void

    init(profile: Profile, tabManager: TabManager, showFXAClosure: @escaping (FXAClosureType) -> Void) {
        self.profile = profile
        self.prefs = profile.prefs
        self.tabManager = tabManager
        self.showFXAClosure = showFXAClosure
    }

    // If we do not have the LatestAppVersionProfileKey in the profile, that means that this is a fresh install and we
    // do not show the What's New. If we do have that value, we compare it to the major version of the running app.
    // If it is different then this is an upgrade, downgrades are not possible, so we can show the What's New page.
    func shouldShowWhatsNew() -> Bool {
        guard let latestMajorAppVersion = prefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first else {
            return false // Clean install, never show What's New
        }

        return latestMajorAppVersion != AppInfo.majorAppVersion && DeviceInfo.hasConnectivity()
    }

    // TODO: laurie rename PageOptionsVC ?
    func getToolbarActions(navigationController: UINavigationController?, pageOptionsVC: PageOptionsVC) -> [[PhotonActionSheetItem]] {
        var actions: [[PhotonActionSheetItem]] = []

        let syncAction = syncMenuButton(showFxA: showFXAClosure)
        let section0 = getLibraryActions(vcDelegate: pageOptionsVC)
        var section1 = getOtherPanelActions(vcDelegate: pageOptionsVC)
        let section2 = getSettingsAction(vcDelegate: pageOptionsVC)
        let viewLogins = getViewLoginsAction(navigationController: navigationController)

        let optionalActions = [viewLogins, syncAction].compactMap { $0 }
        if !optionalActions.isEmpty {
            section1.append(contentsOf: optionalActions)
        }

        if let whatsNewAction = getWhatsNewAction() {
            section1.append(whatsNewAction)
        }

        actions.append(contentsOf: [section0, section1, section2])
        return actions
    }

    private func getWhatsNewAction() -> PhotonActionSheetItem? {
        var whatsNewAction: PhotonActionSheetItem?
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

            // Redraw the toolbar so the badge hides from the appMenu button.
            delegate?.updateToolbarState()
        }

        whatsNewAction = PhotonActionSheetItem(title: .WhatsNewString, iconString: "whatsnew", isEnabled: showBadgeForWhatsNew) { _, _ in
            if let whatsNewTopic = AppInfo.whatsNewTopic, let whatsNewURL = SupportUtils.URLForTopic(whatsNewTopic) {
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .whatsNew)
                delegate?.openURLInNewTab(whatsNewURL, isPrivate: false)
            }
        }
        return whatsNewAction
    }

    typealias NavigationHandlerType = ((_ url: URL?) -> Void)
    private func getViewLoginsAction(navigationController: UINavigationController?) -> PhotonActionSheetItem? {
        let isLoginsButtonShowing = LoginListViewController.shouldShowAppMenuShortcut(forPrefs: prefs)
        guard isLoginsButtonShowing else { return nil }

        return PhotonActionSheetItem(title: .AppMenuPasswords,
                                     iconString: "key",
                                     iconType: .Image,
                                     iconAlignment: .left,
                                     isEnabled: true) { _, _ in

            guard let navigationController = navigationController else { return }
            let navigationHandler: NavigationHandlerType = { url in
                UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                self.delegate?.openURLInNewTab(url, isPrivate: false)
            }

            if AppAuthenticator.canAuthenticateDeviceOwner() {
                if LoginOnboarding.shouldShow() {
                    showLoginOnboarding(navigationHandler: navigationHandler, navigationController: navigationController)
                } else {
                    showLoginListVC(navigationHandler: navigationHandler, navigationController: navigationController)
                }

            } else {
                let rootViewController = DevicePasscodeRequiredViewController(shownFromAppMenu: true)
                let navController = ThemedNavigationController(rootViewController: rootViewController)
                self.delegate?.presentViewController(viewController: navController)
            }
        }
    }

    private func showLoginOnboarding(navigationHandler: @escaping NavigationHandlerType, navigationController: UINavigationController) {
        let loginOnboardingViewController = LoginOnboardingViewController(shownFromAppMenu: true)
        loginOnboardingViewController.doneHandler = {
            loginOnboardingViewController.dismiss(animated: true)
        }

        loginOnboardingViewController.proceedHandler = {
            loginOnboardingViewController.dismiss(animated: true) {
                showLoginListVC(navigationHandler: navigationHandler, navigationController: navigationController)
            }
        }

        let navController = ThemedNavigationController(rootViewController: loginOnboardingViewController)
        delegate?.presentViewController(viewController: navController)

        LoginOnboarding.setShown()
    }

    private func showLoginListVC(navigationHandler: @escaping NavigationHandlerType, navigationController: UINavigationController) {
        guard let settingsDelegate = settingsDelegate else { return }
        LoginListViewController.create(authenticateInNavigationController: navigationController,
                                       profile: self.profile,
                                       settingsDelegate: settingsDelegate,
                                       webpageNavigationHandler: navigationHandler).uponQueue(.main) { loginsVC in
            presentLoginList(loginsVC)
        }
    }

    private func presentLoginList(_ loginsVC: LoginListViewController?) {
        guard let loginsVC = loginsVC else { return }
        loginsVC.shownFromAppMenu = true
        let navController = ThemedNavigationController(rootViewController: loginsVC)
        delegate?.presentViewController(viewController: navController)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .logins)
    }
}
