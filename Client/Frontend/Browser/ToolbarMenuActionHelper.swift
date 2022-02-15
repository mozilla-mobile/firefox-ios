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

    private let isHomePage: Bool
    let profile: Profile
    let tabManager: TabManager

    weak var delegate: ToolBarActionMenuDelegate?
    weak var menuActionDelegate: MenuActionsDelegate?

    var showFXAClosure: (FXAClosureType) -> Void

    init(profile: Profile, isHomePage: Bool, tabManager: TabManager, showFXAClosure: @escaping (FXAClosureType) -> Void) {
        self.profile = profile
        self.isHomePage = isHomePage
        self.tabManager = tabManager
        self.showFXAClosure = showFXAClosure
    }

    func getToolbarActions(navigationController: UINavigationController?) -> [[PhotonActionSheetItem]] {
        var actions: [[PhotonActionSheetItem]] = []
        let librarySection = getLibrarySection()
        if isHomePage {
            actions.append(contentsOf: [librarySection, getLastSection()])
        } else {
            // todo; laurie - new tab section
            actions.append(contentsOf: [librarySection,
                                        getFirstMiscSection(navigationController),
                                        getSecondMiscSection(),
                                        getLastSection()])
        }

        return actions
    }

    // MARK: - Private

    private func getLibrarySection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()
        let libraryActions = getLibraryActions(vcDelegate: menuActionDelegate)
        append(to: &section, action: libraryActions)

        let syncAction = syncMenuButton(showFxA: showFXAClosure)
        append(to: &section, action: syncAction)

        return section
    }

    private func getFirstMiscSection(_ navigationController: UINavigationController?) -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        let nightModeAction = getNightModeAction()
        append(to: &section, action: nightModeAction)

        if let navigationController = navigationController {
            let viewLogins = getViewLoginsAction(navigationController: navigationController)
            append(to: &section, action: viewLogins)
        }

        // TODO: laurie - find in page
        // TODO: laurie - passwords
        // TODO: laurie - request desktop site - beta only

        return section
    }

    private func getSecondMiscSection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        // TODO: laurie - shortcuts
        // TODO: laurie - copy link
        // TODO: laurie - send link to device
        // TODO: laurie - share

        return section
    }

    private func getLastSection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        if isHomePage {
            let whatsNewAction = getWhatsNewAction()
            append(to: &section, action: whatsNewAction)

            let helpAction = getHelpAction()
            section.append(helpAction)

            let customizeHomePageAction = getCustomizeHomePageAction()
            append(to: &section, action: customizeHomePageAction)
        }

        let settingsAction = getSettingsAction(vcDelegate: menuActionDelegate)
        section.append(settingsAction)

        return section
    }

    private func getHelpAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppSettingsHelp,
                                     iconString: "help",
                                     isEnabled: true) { _, _ in

            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.openURLInNewTab(url, isPrivate: false)
            }
        }
    }

    private func getCustomizeHomePageAction() -> PhotonActionSheetItem? {
        guard let bvc = menuActionDelegate as? BrowserViewController else { return nil }

        return PhotonActionSheetItem(title: .FirefoxHomepage.CustomizeHomepage.ButtonTitle,
                                     iconString: "edit",
                                     isEnabled: true) { _, _ in

            bvc.homePanelDidRequestToCustomizeHomeSettings()
        }
    }

    private func getWhatsNewAction() -> PhotonActionSheetItem? {
        var whatsNewAction: PhotonActionSheetItem?
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

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
        let isLoginsButtonShowing = LoginListViewController.shouldShowAppMenuShortcut(forPrefs: profile.prefs)
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
        guard let menuActionDelegate = menuActionDelegate else { return }
        LoginListViewController.create(authenticateInNavigationController: navigationController,
                                       profile: self.profile,
                                       settingsDelegate: menuActionDelegate,
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

    // If we do not have the LatestAppVersionProfileKey in the profile, that means that this is a fresh install and we
    // do not show the What's New. If we do have that value, we compare it to the major version of the running app.
    // If it is different then this is an upgrade, downgrades are not possible, so we can show the What's New page.
    private func shouldShowWhatsNew() -> Bool {
        guard let latestMajorAppVersion = profile.prefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first else {
            return false // Clean install, never show What's New
        }

        return latestMajorAppVersion != AppInfo.majorAppVersion && DeviceInfo.hasConnectivity()
    }

    // MARK: - Conveniance

    private func append(to items: inout [PhotonActionSheetItem], action: PhotonActionSheetItem?) {
        if let action = action {
            items.append(action)
        }
    }

    private func append(to items: inout [PhotonActionSheetItem], action: [PhotonActionSheetItem]?) {
        if let action = action {
            items.append(contentsOf: action)
        }
    }
}
