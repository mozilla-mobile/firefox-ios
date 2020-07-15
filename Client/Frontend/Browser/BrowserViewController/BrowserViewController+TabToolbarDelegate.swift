/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

extension BrowserViewController: TabToolbarDelegate, PhotonActionSheetProtocol {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.reload()
    }

    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard let tab = tabManager.selectedTab else {
            return
        }
        let urlActions = self.getRefreshLongPressMenu(for: tab)
        guard !urlActions.isEmpty else {
            return
        }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        presentSheetWith(actions: [urlActions], on: self, from: button, suppressPopover: shouldSuppress)
    }

    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.stop()
    }

    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goForward()
    }

    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressLibrary(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        if let libraryDrawerViewController = self.libraryDrawerViewController, libraryDrawerViewController.isOpen {
            libraryDrawerViewController.close()
        } else {
            showLibrary()
        }
    }
    
    func tabToolbarDidPressAddNewTab(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        tabManager.selectTab(tabManager.addTab(nil, isPrivate: isPrivate))
        focusLocationTextField(forTab: tabManager.selectedTab)
    }

    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        var whatsNewAction: PhotonActionSheetItem? = nil
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
            // Redraw the toolbar so the badge hides from the appMenu button.
            updateToolbarStateForTraitCollection(view.traitCollection)
        }
        whatsNewAction = PhotonActionSheetItem(title: Strings.WhatsNewString, iconString: "whatsnew", isEnabled: showBadgeForWhatsNew, badgeIconNamed: "menuBadge") { _, _ in
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
            PhotonActionSheetItem(title: Strings.LoginsAndPasswordsTitle, iconString: "key", iconType: .Image, iconAlignment: .left, isEnabled: true) { _, _ in
            guard let navController = self.navigationController else { return }
            LoginListViewController.create(authenticateInNavigationController: navController, profile: self.profile, settingsDelegate: self).uponQueue(.main) { loginsVC in
                guard let loginsVC = loginsVC else { return }
                loginsVC.shownFromAppMenu = true
                let navController = ThemedNavigationController(rootViewController: loginsVC)
                self.present(navController, animated: true)
            }
        }

        let optionalActions = [syncAction, viewLogins].compactMap { $0 }
        if !optionalActions.isEmpty {
            actions.append(optionalActions)
        }

        actions.append(getLibraryActions(vcDelegate: self))
        actions.append(getOtherPanelActions(vcDelegate: self))

        if let whatsNewAction = whatsNewAction, var lastGroup = actions.last, lastGroup.count > 1 {
            lastGroup.insert(whatsNewAction, at: lastGroup.count - 1)
            actions.removeLast()
            actions.append(lastGroup)
        }

        // force a modal if the menu is being displayed in compact split screen
        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        presentSheetWith(actions: actions, on: self, from: button, suppressPopover: shouldSuppress)
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

        let privateBrowsingMode = PhotonActionSheetItem(title: Strings.privateBrowsingModeTitle, iconString: "nav-tabcounter", iconType: .TabsButton, tabCount: tabCount) { _, _ in
            action()
        }
        let normalBrowsingMode = PhotonActionSheetItem(title: Strings.normalBrowsingModeTitle, iconString: "nav-tabcounter", iconType: .TabsButton, tabCount: tabCount) { _, _ in
            action()
        }

        if let tab = self.tabManager.selectedTab {
            return tab.isPrivate ? [normalBrowsingMode] : [privateBrowsingMode]
        }
        return [privateBrowsingMode]
    }

    func getMoreTabToolbarLongPressActions() -> [PhotonActionSheetItem] {
        let newTab = PhotonActionSheetItem(title: Strings.NewTabTitle, iconString: "quick_action_new_tab", iconType: .Image) { _, _ in
            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false)}
        let newPrivateTab = PhotonActionSheetItem(title: Strings.NewPrivateTabTitle, iconString: "quick_action_new_tab", iconType: .Image) { _, _ in
            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: true)}
        let closeTab = PhotonActionSheetItem(title: Strings.CloseTabTitle, iconString: "tab_close", iconType: .Image) { _, _ in
            if let tab = self.tabManager.selectedTab {
                self.tabManager.removeTabAndUpdateSelectedIndex(tab)
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

        // Force a modal if the menu is being displayed in compact split screen.
        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        presentSheetWith(actions: actions, on: self, from: button, suppressPopover: shouldSuppress)
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

