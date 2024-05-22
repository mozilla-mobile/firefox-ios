// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

extension BrowserViewController: TabToolbarDelegate, PhotonActionSheetProtocol {
    // MARK: Data Clearance CFR / Contextual Hint

    // Reset the CFR timer for the data clearance button to avoid presenting the CFR
    // In cases, such as if user navigates to homepage or if fire icon is not available
    func resetDataClearanceCFRTimer() {
        dataClearanceContextHintVC.stopTimer()
    }

    func configureDataClearanceContextualHint() {
        guard !isToolbarRefactorEnabled,
                contentContainer.hasWebView,
                tabManager.selectedTab?.url?.displayURL?.isWebPage() == true
        else {
            resetDataClearanceCFRTimer()
            return
        }
        dataClearanceContextHintVC.configure(
            anchor: navigationToolbar.multiStateButton,
            withArrowDirection: topTabsVisible ? .up : .down,
            andDelegate: self,
            presentedUsing: { [weak self] in self?.presentDataClearanceContextualHint() },
            andActionForButton: { },
            overlayState: overlayManager)
    }

    private func presentDataClearanceContextualHint() {
        present(dataClearanceContextHintVC, animated: true)
        UIAccessibility.post(notification: .layoutChanged, argument: dataClearanceContextHintVC)
    }

    func tabToolbarDidPressHome(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        didTapOnHome()
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
            style: .default,
            handler: { [weak self] _ in
                self?.privateBrowsingTelemetry.sendDataClearanceTappedTelemetry(didConfirm: false)
            }
        )

        let deleteDataAction = UIAlertAction(
            title: .Alerts.FeltDeletion.ConfirmButton,
            style: .destructive,
            handler: { [weak self] _ in
                self?.privateBrowsingTelemetry.sendDataClearanceTappedTelemetry(didConfirm: true)
                self?.setupDataClearanceAnimation { timingConstant in
                    DispatchQueue.main.asyncAfter(deadline: .now() + timingConstant) {
                        self?.closePrivateTabsAndOpenNewPrivateHomepage()
                        self?.showDataClearanceConfirmationToast()
                    }
                }
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
                theme: self.currentTheme()
            )
        }
    }

    /// Setup animation for data clearance flow unless reduce motion is enabled
    /// - Parameter completion: returns the proper timing to match animation on when to close tabs and display toast
    private func setupDataClearanceAnimation(completion: @escaping (Double) -> Void) {
        let showAnimation = !UIAccessibility.isReduceMotionEnabled
        let timingToMatchGradientOverlay = showAnimation ? 0.8 : 0.0

        guard showAnimation else {
            completion(timingToMatchGradientOverlay)
            return
        }
        let dataClearanceAnimation = DataClearanceAnimation()
        dataClearanceAnimation.startAnimation(
            with: view,
            for: shouldShowTopTabsForTraitCollection(
                traitCollection
            )
        )

        completion(timingToMatchGradientOverlay)
    }

    func tabToolbarDidPressLibrary(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
    }

    func dismissUrlBar() {
        if !isToolbarRefactorEnabled, urlBar.inOverlayMode {
            urlBar.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        }
    }

    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        // This code snippet addresses an issue related to navigation between pages in the same tab FXIOS-7309.
        // Specifically, it checks if the URL bar is not currently focused (`!focusUrlBar`) and if it is
        // operating in an overlay mode (`urlBar.inOverlayMode`).
        dismissUrlBar()
        updateZoomPageBarVisibility(visible: false)
        tabManager.selectedTab?.goBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        handleTabToolBarDidLongPressForwardOrBack()
    }

    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        // This code snippet addresses an issue related to navigation between pages in the same tab FXIOS-7309.
        // Specifically, it checks if the URL bar is not currently focused (`!focusUrlBar`) and if it is
        // operating in an overlay mode (`urlBar.inOverlayMode`).
        dismissUrlBar()
        updateZoomPageBarVisibility(visible: false)
        tabManager.selectedTab?.goForward()
    }

    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        handleTabToolBarDidLongPressForwardOrBack()
    }

    private func handleTabToolBarDidLongPressForwardOrBack() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        navigationHandler?.showBackForwardList()
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
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )

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
            let shouldInverse = PhotonActionSheetViewModel.hasInvertedMainMenu(
                trait: self.traitCollection,
                isBottomSearchBar: self.isBottomSearchBar
            )
            let viewModel = PhotonActionSheetViewModel(
                actions: actions,
                modalStyle: .popover,
                isMainMenu: true,
                isMainMenuInverted: shouldInverse
            )
            self.presentSheetWith(viewModel: viewModel, on: self, from: button)
        }
    }

    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        updateZoomPageBarVisibility(visible: false)
        let isPrivateTab = tabManager.selectedTab?.isPrivate ?? false
        let segmentToFocus = isPrivateTab ? TabTrayPanelType.privateTabs : TabTrayPanelType.tabs
        showTabTray(focusedSegment: segmentToFocus)
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .press,
            object: .tabToolbar,
            value: .tabView
        )
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
                                                        iconString: StandardImageIdentifiers.Large.tab,
                                                        iconType: .TabsButton,
                                                        tabCount: tabCount) { _ in
            action()
        }.items

        let normalBrowsingMode = SingleActionViewModel(title: .KeyboardShortcuts.NormalBrowsingMode,
                                                       iconString: StandardImageIdentifiers.Large.tab,
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
                self.showToast(message: .TabsTray.CloseTabsToast.SingleTabTitle, toastAction: .closeTab)
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

        let viewModel = PhotonActionSheetViewModel(
            actions: actions,
            closeButtonTitle: .CloseButtonTitle,
            modalStyle: .overCurrentContext
        )
        presentSheetWith(viewModel: viewModel, on: self, from: button)
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

    func showToast(_ bookmarkURL: URL? = nil, _ title: String?, message: String, toastAction: MenuButtonToastAction) {
        switch toastAction {
        case .bookmarkPage:
            let viewModel = ButtonToastViewModel(labelText: message,
                                                 buttonText: .BookmarksEdit,
                                                 textAlignment: .left)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme()) { isButtonTapped in
                isButtonTapped ? self.openBookmarkEditPanel() : nil
            }
            self.show(toast: toast)
        case .removeBookmark:
            let viewModel = ButtonToastViewModel(labelText: message,
                                                 buttonText: .UndoString,
                                                 textAlignment: .left)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme()) { [weak self] isButtonTapped in
                guard let self, let currentTab = tabManager.selectedTab else { return }
                isButtonTapped ? self.addBookmark(
                    url: bookmarkURL?.absoluteString ?? currentTab.url?.absoluteString ?? "",
                    title: title ?? currentTab.title
                ) : nil
            }
            show(toast: toast)
        case .closeTab:
            let viewModel = ButtonToastViewModel(labelText: message,
                                                 buttonText: .UndoString,
                                                 textAlignment: .left)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme()) { [weak self] isButtonTapped in
                guard let self,
                        tabManager.backupCloseTab != nil,
                        isButtonTapped
                else { return }
                self.tabManager.undoCloseTab()
            }
            show(toast: toast)
        default:
            SimpleToast().showAlertWithText(message,
                                            bottomContainer: contentContainer,
                                            theme: currentTheme())
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
