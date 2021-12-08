// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared

extension BrowserViewController: TabToolbarDelegate, PhotonActionSheetProtocol {
    func tabToolbarDidPressHome(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let page = NewTabAccessors.getHomePage(self.profile.prefs)
        if page == .homePage, let homePageURL = HomeButtonHomePageAccessors.getHomePage(self.profile.prefs) {
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: homePageURL) as URLRequest)
        } else if let homePanelURL = page.url {
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: homePanelURL) as URLRequest)
        }
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .home)
    }

    func tabToolbarDidPressLibrary(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
    }
    
    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.reload()
    }
    
    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        
        let urlActions = self.getRefreshLongPressMenu(for: tab)
        guard !urlActions.isEmpty else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        let shouldSuppress = UIDevice.current.userInterfaceIdiom != .pad
        
        presentSheetWith(actions: [urlActions], on: self, from: button, suppressPopover: shouldSuppress)
    }
    
    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.stop()
    }
    
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goForward()
    }

    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressBookmarks(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        if let libraryDrawerViewController = self.libraryDrawerViewController, libraryDrawerViewController.isOpen {
            libraryDrawerViewController.close()
        } else {
            showLibrary(panel: .bookmarks)
        }
    }
    
    func tabToolbarDidPressAddNewTab(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        tabManager.selectTab(tabManager.addTab(nil, isPrivate: isPrivate))
        focusLocationTextField(forTab: tabManager.selectedTab)
    }

    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        var whatsNewAction: PhotonActionSheetItem?
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
            // Redraw the toolbar so the badge hides from the appMenu button.
            updateToolbarStateForTraitCollection(view.traitCollection)
        }
        whatsNewAction = PhotonActionSheetItem(title: .WhatsNewString, iconString: "whatsnew", isEnabled: showBadgeForWhatsNew) { _, _ in
            if let whatsNewTopic = AppInfo.whatsNewTopic, let whatsNewURL = SupportUtils.URLForTopic(whatsNewTopic) {
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .whatsNew)
                self.openURLInNewTab(whatsNewURL)
            }
        }

        // ensure that any keyboards or spinners are dismissed before presenting the menu
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        libraryDrawerViewController?.close(immediately: true)
        var actions: [[PhotonActionSheetItem]] = []

        let syncAction = syncMenuButton(showFxA: presentSignInViewController)
        let isLoginsButtonShowing = LoginListViewController.shouldShowAppMenuShortcut(forPrefs: profile.prefs)
        let viewLogins: PhotonActionSheetItem? = !isLoginsButtonShowing ? nil :
            PhotonActionSheetItem(title: .AppMenuPasswords, iconString: "key", iconType: .Image, iconAlignment: .left, isEnabled: true) { _, _ in
                guard let navController = self.navigationController else { return }
                let navigationHandler: ((_ url: URL?) -> Void) = { url in
                    UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                    self.openURLInNewTab(url)
                }
                            
                if AppAuthenticator.canAuthenticateDeviceOwner() {
                    if LoginOnboarding.shouldShow() {
                        let loginOnboardingViewController = LoginOnboardingViewController(shownFromAppMenu: true)
                        loginOnboardingViewController.doneHandler = {
                            loginOnboardingViewController.dismiss(animated: true)
                        }
                        
                        loginOnboardingViewController.proceedHandler = {
                            loginOnboardingViewController.dismiss(animated: true) {
                                LoginListViewController.create(authenticateInNavigationController: navController, profile: self.profile, settingsDelegate: self, webpageNavigationHandler: navigationHandler).uponQueue(.main) { loginsVC in
                                    guard let loginsVC = loginsVC else { return }
                                    loginsVC.shownFromAppMenu = true
                                    let navController = ThemedNavigationController(rootViewController: loginsVC)
                                    self.present(navController, animated: true)
                                    TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .logins)
                                }
                            }
                        }
                        
                        let navController = ThemedNavigationController(rootViewController: loginOnboardingViewController)
                        self.present(navController, animated: true)
                        
                        LoginOnboarding.setShown()
                    } else {
                        LoginListViewController.create(authenticateInNavigationController: navController, profile: self.profile, settingsDelegate: self, webpageNavigationHandler: navigationHandler).uponQueue(.main) { loginsVC in
                            guard let loginsVC = loginsVC else { return }
                            loginsVC.shownFromAppMenu = true
                            let navController = ThemedNavigationController(rootViewController: loginsVC)
                            self.present(navController, animated: true)
                            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .logins)
                        }
                    }
                } else {
                    let navController = ThemedNavigationController(rootViewController: DevicePasscodeRequiredViewController(shownFromAppMenu: true))
                    self.present(navController, animated: true)
                }
            }
        
        let section0 = getLibraryActions(vcDelegate: self)
        var section1 = getOtherPanelActions(vcDelegate: self)
        let section2 = getSettingsAction(vcDelegate: self)
        
        let optionalActions = [viewLogins, syncAction].compactMap { $0 }
        if !optionalActions.isEmpty {
            section1.append(contentsOf: optionalActions)
        }
        
        if let whatsNewAction = whatsNewAction {
            section1.append(whatsNewAction)
        }
        
        actions.append(contentsOf: [section0, section1, section2])

        presentSheetWith(actions: actions, on: self, from: button)
    }

    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        showTabTray()
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .tabToolbar, value: .tabView)
    }

    func getTabToolbarLongPressActionsForModeSwitching() -> [PhotonActionSheetItem] {
        guard let selectedTab = tabManager.selectedTab else { return [] }
        let count = selectedTab.isPrivate ? tabManager.normalTabs.count : tabManager.privateTabs.count
        let infinity = "\u{221E}"
        let tabCount = (count < 100) ? count.description : infinity

        func action() {
            let result = tabManager.switchPrivacyMode()
            if result == .createdNewTab, NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage {
                focusLocationTextField(forTab: tabManager.selectedTab)
            }
        }

        let privateBrowsingMode = PhotonActionSheetItem(title: .KeyboardShortcuts.PrivateBrowsingMode, iconString: "nav-tabcounter", iconType: .TabsButton, tabCount: tabCount) { _, _ in
            action()
        }
        let normalBrowsingMode = PhotonActionSheetItem(title: .KeyboardShortcuts.NormalBrowsingMode, iconString: "nav-tabcounter", iconType: .TabsButton, tabCount: tabCount) { _, _ in
            action()
        }

        if let tab = self.tabManager.selectedTab {
            return tab.isPrivate ? [normalBrowsingMode] : [privateBrowsingMode]
        }
        return [privateBrowsingMode]
    }

    func getMoreTabToolbarLongPressActions() -> [PhotonActionSheetItem] {
        let newTab = PhotonActionSheetItem(title: .KeyboardShortcuts.NewTab, iconString: "quick_action_new_tab", iconType: .Image) { _, _ in
            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false)
        }
        let newPrivateTab = PhotonActionSheetItem(title: .KeyboardShortcuts.NewPrivateTab, iconString: "quick_action_new_tab", iconType: .Image) { _, _ in
            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: true)}
        let closeTab = PhotonActionSheetItem(title: .KeyboardShortcuts.CloseCurrentTab, iconString: "tab_close", iconType: .Image) { _, _ in
            if let tab = self.tabManager.selectedTab {
                self.tabManager.removeTab(tab)
                self.updateTabCountUsingTabManager(self.tabManager)
            }}
        if let tab = self.tabManager.selectedTab {
            return tab.isPrivate ? [newPrivateTab, closeTab] : [newTab, closeTab]
        }
        return [newTab, closeTab]
    }

    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard self.presentedViewController == nil else {
            return
        }
        var actions: [[PhotonActionSheetItem]] = []
        actions.append(getTabToolbarLongPressActionsForModeSwitching())
        actions.append(getMoreTabToolbarLongPressActions())

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        presentSheetWith(actions: actions, on: self, from: button, suppressPopover: true)
    }

    func showBackForwardList() {
        if let backForwardList = tabManager.selectedTab?.webView?.backForwardList {
            let backForwardViewController = BackForwardListViewController(profile: profile, backForwardList: backForwardList)
            backForwardViewController.tabManager = tabManager
            backForwardViewController.bvc = self
            backForwardViewController.modalPresentationStyle = .overCurrentContext
            backForwardViewController.backForwardTransitionDelegate = BackForwardListAnimator()
            self.present(backForwardViewController, animated: true, completion: nil)
        }
    }

    func tabToolbarDidPressSearch(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        focusLocationTextField(forTab: tabManager.selectedTab)
    }
}

