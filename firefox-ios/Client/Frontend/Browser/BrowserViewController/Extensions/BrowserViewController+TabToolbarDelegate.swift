// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

extension BrowserViewController: TabToolbarDelegate, PhotonActionSheetProtocol {
    func tabToolbarDidPressHome(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        updateZoomPageBarVisibility(visible: false)
        userHasPressedHomeButton = true
        let page = NewTabAccessors.getHomePage(self.profile.prefs)
        if page == .homePage, let homePageURL = HomeButtonHomePageAccessors.getHomePage(self.profile.prefs) {
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: homePageURL) as URLRequest)
        } else if let homePanelURL = page.url {
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: homePanelURL) as URLRequest)
        }
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .home)
    }

    // Presents alert to clear users private session data
    func tabToolbarDidPressFire(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let alert = UIAlertController(
            title: .Alerts.FeltDeletion.Title,
            message: .Alerts.FeltDeletion.Body,
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: .Alerts.FeltDeletion.CancelButton,
            style: .cancel,
            handler: nil
        )

        let deleteDataAction = UIAlertAction(
            title: .Alerts.FeltDeletion.ConfirmButton,
            style: .destructive,
            handler: { [weak self] _ in
                self?.closePrivateTabsAndOpenNewPrivateHomepage()
                self?.showDataClearanceConfirmationToast()
            }
        )

        alert.addAction(deleteDataAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func closePrivateTabsAndOpenNewPrivateHomepage() {
        tabManager.removeTabs(tabManager.privateTabs)
        tabManager.selectTab(tabManager.addTab(isPrivate: true))
    }

    private func showDataClearanceConfirmationToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            SimpleToast().showAlertWithText(
                .FirefoxHomepage.FeltDeletion.ToastTitle,
                bottomContainer: self.contentContainer,
                theme: self.themeManager.currentTheme
            )
        }
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

        let shouldSuppress = UIDevice.current.userInterfaceIdiom == .pad
        let style: UIModalPresentationStyle = shouldSuppress ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(actions: [urlActions], closeButtonTitle: .CloseButtonTitle, modalStyle: style)
        presentSheetWith(viewModel: viewModel, on: self, from: button)
    }

    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.stop()
    }

    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        updateZoomPageBarVisibility(visible: false)
        tabManager.selectedTab?.goBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        updateZoomPageBarVisibility(visible: false)
        tabManager.selectedTab?.goForward()
    }

    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressBookmarks(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        showLibrary(panel: .bookmarks)
    }

    func tabToolbarDidPressAddNewTab(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        tabManager.selectTab(tabManager.addTab(nil, isPrivate: isPrivate))
        focusLocationTextField(forTab: tabManager.selectedTab)
        overlayManager.openNewTab(url: nil,
                                  newTabSettings: NewTabAccessors.getNewTabPage(profile.prefs))
    }

    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        // Ensure that any keyboards or spinners are dismissed before presenting the menu
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Logs homePageMenu or siteMenu depending if HomePage is open or not
        let isHomePage = tabManager.selectedTab?.isFxHomeTab ?? false
        let eventObject: TelemetryWrapper.EventObject = isHomePage ? .homePageMenu : .siteMenu
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: eventObject)
        let menuHelper = MainMenuActionHelper(profile: profile,
                                              tabManager: tabManager,
                                              buttonView: button,
                                              toastContainer: contentContainer)
        menuHelper.delegate = self
        menuHelper.sendToDeviceDelegate = self
        menuHelper.navigationHandler = navigationHandler

        updateZoomPageBarVisibility(visible: false)
        menuHelper.getToolbarActions(navigationController: navigationController) { actions in
            let shouldInverse = PhotonActionSheetViewModel.hasInvertedMainMenu(trait: self.traitCollection, isBottomSearchBar: self.isBottomSearchBar)
            let viewModel = PhotonActionSheetViewModel(actions: actions, modalStyle: .popover, isMainMenu: true, isMainMenuInverted: shouldInverse)
            self.presentSheetWith(viewModel: viewModel, on: self, from: button)
        }
    }

    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        updateZoomPageBarVisibility(visible: false)
        let segmentToFocus = tabManager.selectedTab?.isPrivate ?? false ? TabTrayPanelType.privateTabs : TabTrayPanelType.tabs
        showTabTray(focusedSegment: segmentToFocus)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .tabToolbar, value: .tabView)
    }

    func getTabToolbarLongPressActionsForModeSwitching() -> [PhotonRowActions] {
        guard let selectedTab = tabManager.selectedTab else { return [] }
        let count = selectedTab.isPrivate ? tabManager.normalTabs.count : tabManager.privateTabs.count
        let infinity = "\u{221E}"
        let tabCount = (count < 100) ? count.description : infinity

        func action() {
            let result = tabManager.switchPrivacyMode()
            if result == .createdNewTab, self.newTabSettings == .blankPage {
                focusLocationTextField(forTab: tabManager.selectedTab)
            }
        }

        let privateBrowsingMode = SingleActionViewModel(title: .KeyboardShortcuts.PrivateBrowsingMode,
                                                        iconString: "nav-tabcounter",
                                                        iconType: .TabsButton,
                                                        tabCount: tabCount) { _ in
            action()
        }.items

        let normalBrowsingMode = SingleActionViewModel(title: .KeyboardShortcuts.NormalBrowsingMode,
                                                       iconString: "nav-tabcounter",
                                                       iconType: .TabsButton,
                                                       tabCount: tabCount) { _ in
            action()
        }.items

        if let tab = self.tabManager.selectedTab {
            return tab.isPrivate ? [normalBrowsingMode] : [privateBrowsingMode]
        }
        return [privateBrowsingMode]
    }

    func getMoreTabToolbarLongPressActions() -> [PhotonRowActions] {
        let newTab = SingleActionViewModel(title: .KeyboardShortcuts.NewTab,
                                           iconString: StandardImageIdentifiers.Large.plus,
                                           iconType: .Image) { _ in
            let shouldFocusLocationField = self.newTabSettings == .blankPage
            self.overlayManager.openNewTab(url: nil, newTabSettings: self.newTabSettings)
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false)
        }.items

        let newPrivateTab = SingleActionViewModel(title: .KeyboardShortcuts.NewPrivateTab,
                                                  iconString: StandardImageIdentifiers.Large.plus,
                                                  iconType: .Image) { _ in
            let shouldFocusLocationField = self.newTabSettings == .blankPage
            self.overlayManager.openNewTab(url: nil, newTabSettings: self.newTabSettings)
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: true)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .newPrivateTab, value: .tabTray)
        }.items

        let closeTab = SingleActionViewModel(title: .KeyboardShortcuts.CloseCurrentTab,
                                             iconString: StandardImageIdentifiers.Large.cross,
                                             iconType: .Image) { _ in
            if let tab = self.tabManager.selectedTab {
                self.tabManager.removeTab(tab)
                self.updateTabCountUsingTabManager(self.tabManager)
            }
        }.items

        if let tab = self.tabManager.selectedTab {
            return tab.isPrivate ? [newPrivateTab, closeTab] : [newTab, closeTab]
        }
        return [newTab, closeTab]
    }

    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard self.presentedViewController == nil else { return }
        var actions: [[PhotonRowActions]] = []
        actions.append(getTabToolbarLongPressActionsForModeSwitching())
        actions.append(getMoreTabToolbarLongPressActions())

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let viewModel = PhotonActionSheetViewModel(actions: actions, closeButtonTitle: .CloseButtonTitle, modalStyle: .overCurrentContext)
        presentSheetWith(viewModel: viewModel, on: self, from: button)
    }

    func showBackForwardList() {
        if let backForwardList = tabManager.selectedTab?.webView?.backForwardList {
            let backForwardViewController = BackForwardListViewController(profile: profile, backForwardList: backForwardList)
            backForwardViewController.tabManager = tabManager
            backForwardViewController.browserFrameInfoProvider = self
            backForwardViewController.modalPresentationStyle = .overCurrentContext
            backForwardViewController.backForwardTransitionDelegate = BackForwardListAnimator()
            self.present(backForwardViewController, animated: true, completion: nil)
        }
    }

    func tabToolbarDidPressSearch(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        focusLocationTextField(forTab: tabManager.selectedTab)
    }
}

// MARK: - ToolbarActionMenuDelegate
extension BrowserViewController: ToolBarActionMenuDelegate {
    func updateToolbarState() {
        updateToolbarStateForTraitCollection(view.traitCollection)
    }

    func showViewController(viewController: UIViewController) {
        presentWithModalDismissIfNeeded(viewController, animated: true)
    }

    func showToast(message: String, toastAction: MenuButtonToastAction) {
        switch toastAction {
        case .removeBookmark:
            let viewModel = ButtonToastViewModel(labelText: message,
                                                 buttonText: .UndoString,
                                                 textAlignment: .left)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: themeManager.currentTheme) { [weak self] isButtonTapped in
                guard let strongSelf = self, let currentTab = strongSelf.tabManager.selectedTab else { return }
                isButtonTapped ? strongSelf.addBookmark(url: currentTab.url?.absoluteString ?? "", title: currentTab.title) : nil
            }
            show(toast: toast)
        default:
            SimpleToast().showAlertWithText(message,
                                            bottomContainer: contentContainer,
                                            theme: themeManager.currentTheme)
        }
    }

    func showFindInPage() {
        updateFindInPageVisibility(visible: true)
    }

    func showCustomizeHomePage() {
        navigationHandler?.show(settings: .homePage)
    }

    func showWallpaperSettings() {
        navigationHandler?.show(settings: .wallpaper)
    }

    func showCreditCardSettings() {
        navigationHandler?.show(settings: .creditCard)
    }

    func showZoomPage(tab: Tab) {
        updateZoomPageBarVisibility(visible: true)
    }

    func showSignInView(fxaParameters: FxASignInViewParameters) {
        presentSignInViewController(fxaParameters.launchParameters,
                                    flowType: fxaParameters.flowType,
                                    referringPage: fxaParameters.referringPage)
    }
}
