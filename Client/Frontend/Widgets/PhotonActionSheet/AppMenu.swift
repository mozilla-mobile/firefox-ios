/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Account

extension PhotonActionSheetProtocol {

    //Returns a list of actions which is used to build a menu
    //OpenURL is a closure that can open a given URL in some view controller. It is up to the class using the menu to know how to open it
    func getLibraryActions(vcDelegate: PageOptionsVC) -> [PhotonActionSheetItem] {
        let bookmarks = PhotonActionSheetItem(title: Strings.AppMenuBookmarks, iconString: "menu-panel-Bookmarks") { _, _ in
            let bvc = vcDelegate as? BrowserViewController
            bvc?.showLibrary(panel: .bookmarks)
        }
        let history = PhotonActionSheetItem(title: Strings.AppMenuHistory, iconString: "menu-panel-History") { _, _ in
            let bvc = vcDelegate as? BrowserViewController
            bvc?.showLibrary(panel: .history)
        }
        let downloads = PhotonActionSheetItem(title: Strings.AppMenuDownloads, iconString: "menu-panel-Downloads") { _, _ in
            let bvc = vcDelegate as? BrowserViewController
            bvc?.showLibrary(panel: .downloads)
        }
        let readingList = PhotonActionSheetItem(title: Strings.AppMenuReadingList, iconString: "menu-panel-ReadingList") { _, _ in
            let bvc = vcDelegate as? BrowserViewController
            bvc?.showLibrary(panel: .readingList)
        }

        return [bookmarks, history, downloads, readingList]
    }
    
    func getHomeAction(vcDelegate: Self.PageOptionsVC) -> [PhotonActionSheetItem] {
        guard let tab = self.tabManager.selectedTab else { return [] }
        
        let openHomePage = PhotonActionSheetItem(title: Strings.AppMenuOpenHomePageTitleString, iconString: "menu-Home") { _, _ in
            let page = NewTabAccessors.getHomePage(self.profile.prefs)
            if page == .homePage, let homePageURL = HomeButtonHomePageAccessors.getHomePage(self.profile.prefs) {
                tab.loadRequest(PrivilegedRequest(url: homePageURL) as URLRequest)
            } else if let homePanelURL = page.url {
                tab.loadRequest(PrivilegedRequest(url: homePanelURL) as URLRequest)
            }
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .home)
        }
        
        return [openHomePage]
    }

    func getSettingsAction(vcDelegate: Self.PageOptionsVC) -> [PhotonActionSheetItem] {
        // This method is being called when we the user sees the menu, not just when it's constructed.
        // In that case, we can let sendExposureEvent default to true.
        let variables = Experiments.shared.getVariables(featureId: .nimbusValidation)
        // Get the title and icon for this feature from nimbus.
        // We need to provide defaults if Nimbus doesn't provide them.
        let title = variables.getText("settings-title") ?? Strings.AppMenuSettingsTitleString
        let icon = variables.getString("settings-icon") ?? "menu-Settings"

        let openSettings = PhotonActionSheetItem(title: title, iconString: icon) { _, _ in
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = self.profile
            settingsTableViewController.tabManager = self.tabManager
            settingsTableViewController.settingsDelegate = vcDelegate
            
            let controller = ThemedNavigationController(rootViewController: settingsTableViewController)
            // On iPhone iOS13 the WKWebview crashes while presenting file picker if its not full screen. Ref #6232
            if UIDevice.current.userInterfaceIdiom == .phone {
                controller.modalPresentationStyle = .fullScreen
            }
            controller.presentingModalViewControllerDelegate = vcDelegate
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .settings)
            
            // Wait to present VC in an async dispatch queue to prevent a case where dismissal
            // of this popover on iPad seems to block the presentation of the modal VC.
            DispatchQueue.main.async {
                vcDelegate.present(controller, animated: true, completion: nil)
            }
        }
        return [openSettings]
    }
    
    func getOtherPanelActions(vcDelegate: PageOptionsVC) -> [PhotonActionSheetItem] {
        var items: [PhotonActionSheetItem] = []
        let noImageEnabled = NoImageModeHelper.isActivated(profile.prefs)
        let imageModeTitle = noImageEnabled ? Strings.AppMenuShowImageMode : Strings.AppMenuNoImageMode
        let iconString = noImageEnabled ? "menu-ShowImages" : "menu-NoImageMode"
        let noImageMode = PhotonActionSheetItem(title: imageModeTitle, iconString: iconString, isEnabled: noImageEnabled) { action,_ in
            NoImageModeHelper.toggle(isEnabled: action.isEnabled, profile: self.profile, tabManager: self.tabManager)
            if noImageEnabled {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .blockImagesDisabled)
            } else {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .blockImagesEnabled)
            }
        }

        items.append(noImageMode)

        let nightModeEnabled = NightModeHelper.isActivated(profile.prefs)
        let nightModeTitle = nightModeEnabled ? Strings.AppMenuTurnOffNightMode : Strings.AppMenuTurnOnNightMode
        let nightMode = PhotonActionSheetItem(title: nightModeTitle, iconString: "menu-NightMode", isEnabled: nightModeEnabled) { _, _ in
            NightModeHelper.toggle(self.profile.prefs, tabManager: self.tabManager)

            if nightModeEnabled {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .nightModeDisabled)
            } else {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .nightModeDisabled)
            }

            // If we've enabled night mode and the theme is normal, enable dark theme
            if NightModeHelper.isActivated(self.profile.prefs), ThemeManager.instance.currentName == .normal {
                ThemeManager.instance.current = DarkTheme()
                NightModeHelper.setEnabledDarkTheme(self.profile.prefs, darkTheme: true)
            }
            // If we've disabled night mode and dark theme was activated by it then disable dark theme
            if !NightModeHelper.isActivated(self.profile.prefs), NightModeHelper.hasEnabledDarkTheme(self.profile.prefs), ThemeManager.instance.currentName == .dark {
                ThemeManager.instance.current = NormalTheme()
                NightModeHelper.setEnabledDarkTheme(self.profile.prefs, darkTheme: false)
            }
        }
        items.append(nightMode)

        return items
    }

    func syncMenuButton(showFxA: @escaping (_ params: FxALaunchParams?, _ flowType: FxAPageType,_ referringPage: ReferringPage) -> Void) -> PhotonActionSheetItem? {
        //profile.getAccount()?.updateProfile()

        let action: ((PhotonActionSheetItem, UITableViewCell) -> Void) = { action,_ in
            let fxaParams = FxALaunchParams(query: ["entrypoint": "browsermenu"])
            showFxA(fxaParams, .emailLoginFlow, .appMenu)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)
        }

        let rustAccount = RustFirefoxAccounts.shared
        let needsReauth = rustAccount.accountNeedsReauth()

        guard let userProfile = rustAccount.userProfile else {
            return PhotonActionSheetItem(title: Strings.AppMenuBackUpAndSyncData, iconString: "menu-sync", handler: action)
        }
        let title: String = {
            if rustAccount.accountNeedsReauth() {
                return Strings.FxAAccountVerifyPassword
            }
            return userProfile.displayName ?? userProfile.email
        }()

        let iconString = needsReauth ? "menu-warning" : "placeholder-avatar"

        var iconURL: URL? = nil
        if let str = rustAccount.userProfile?.avatarUrl, let url = URL(string: str) {
            iconURL = url
        }
        let iconType: PhotonActionSheetIconType = needsReauth ? .Image : .URL
        let iconTint: UIColor? = needsReauth ? UIColor.Photon.Yellow60 : nil
        let syncOption = PhotonActionSheetItem(title: title, iconString: iconString, iconURL: iconURL, iconType: iconType, iconTint: iconTint, handler: action)
        return syncOption
    }
}
