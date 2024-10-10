// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

extension BrowserViewController: TabToolbarDelegate, PhotonActionSheetProtocol {
    private struct UX {
        static let menuHintRightMargin: CGFloat = 50
    }
    // MARK: Data Clearance CFR / Contextual Hint

    // Reset the CFR timer for the data clearance button to avoid presenting the CFR
    // In cases, such as if user navigates to homepage or if fire icon is not available
    func resetDataClearanceCFRTimer() {
        dataClearanceContextHintVC.stopTimer()
    }

    func configureDataClearanceContextualHint(_ view: UIView) {
        guard contentContainer.hasWebView,
                tabManager.selectedTab?.url?.displayURL?.isWebPage() == true
        else {
            resetDataClearanceCFRTimer()
            return
        }
        dataClearanceContextHintVC.configure(
            anchor: view,
            withArrowDirection: ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection) ? .down : .up,
            andDelegate: self,
            presentedUsing: { [weak self] in self?.presentDataClearanceContextualHint() },
            andActionForButton: { },
            overlayState: overlayManager)
    }

    private func presentDataClearanceContextualHint() {
        present(dataClearanceContextHintVC, animated: true)
        UIAccessibility.post(notification: .layoutChanged, argument: dataClearanceContextHintVC)
    }

    // Starts a timer to monitor for a navigation button double tap for the navigation contextual hint
    func startNavigationButtonDoubleTapTimer() {
        guard isToolbarRefactorEnabled, isToolbarNavigationHintEnabled else { return }
        if navigationHintDoubleTapTimer == nil {
            navigationHintDoubleTapTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.navigationHintDoubleTapTimer = nil
            }
        } else {
            navigationHintDoubleTapTimer = nil
            let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.navigationButtonDoubleTapped)
            store.dispatch(action)
        }
    }

    func configureNavigationContextualHint(_ view: UIView) {
        guard isToolbarRefactorEnabled, isToolbarNavigationHintEnabled else { return }
        navigationContextHintVC.configure(
            anchor: view,
            withArrowDirection: ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection) ? .down : .up,
            andDelegate: self,
            presentedUsing: { [weak self] in self?.presentNavigationContextualHint() },
            actionOnDismiss: {
                let action = ToolbarAction(windowUUID: self.windowUUID,
                                           actionType: ToolbarActionType.navigationHintFinishedPresenting)
                store.dispatch(action)
            },
            andActionForButton: { },
            overlayState: overlayManager,
            ignoreSafeArea: true)
    }

    private func presentNavigationContextualHint() {
        // Only show the contextual hint if:
        // 1. The tab webpage is loaded OR we are on the home page, and the
        // 2. Microsurvey prompt is not being displayed
        // If the hint does not show,
        // ToolbarActionType.navigationButtonDoubleTapped will have to be dispatched again through user action
        guard let state = store.state.screenState(BrowserViewControllerState.self,
                                                  for: .browserViewController,
                                                  window: windowUUID)
        else { return }

        if let selectedTab = tabManager.selectedTab,
            selectedTab.isFxHomeTab || !selectedTab.loading,
            !state.microsurveyState.showPrompt {
            present(navigationContextHintVC, animated: true)
            UIAccessibility.post(notification: .layoutChanged, argument: navigationContextHintVC)
        } else {
            let action = ToolbarAction(windowUUID: self.windowUUID,
                                       actionType: ToolbarActionType.navigationHintFinishedPresenting)
            store.dispatch(action)
        }
    }

    func configureMenuContextualHint(_ view: UIView) {
        guard isToolbarRefactorEnabled, isNewMenuEnabled, isNewMenuHintEnabled else { return }
        menuContextHintVC.configure(
            anchor: view,
            withArrowDirection: ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection) ? .down : .up,
            andDelegate: self,
            presentedUsing: { [weak self] in self?.presentMenuContextualHint() },
            overlayState: overlayManager,
            ignoreSafeArea: true,
            rightSafeAreaMargin: !ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection) &&
            UIDevice.current.userInterfaceIdiom == .phone ? UX.menuHintRightMargin : nil)
    }

    private func presentMenuContextualHint() {
        // Only show the menu hint if:
        // 1. The tab webpage is loaded,
        // 2. Micro-survey prompt is not being displayed and
        // 3. Hint was NOT already presented when menu was opened.
        // 4. Do not present hint for new users/fresh install
        guard let state = store.state.screenState(BrowserViewControllerState.self,
                                                  for: .browserViewController,
                                                  window: windowUUID)
        else { return }

        if let selectedTab = tabManager.selectedTab,
           !selectedTab.isFxHomeTab && !selectedTab.loading,
           !state.microsurveyState.showPrompt,
           profile.prefs.boolForKey(PrefsKeys.mainMenuHintKey) == nil,
           InstallType.get() != .fresh {
            present(menuContextHintVC, animated: true)
            UIAccessibility.post(notification: .layoutChanged, argument: menuContextHintVC)
        }
    }

    func tabToolbarDidPressHome(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        didTapOnHome()
    }

    // Presents alert to clear users private session data
    func tabToolbarDidPressDataClearance(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        didTapOnDataClearance()
    }

    func didTapOnDataClearance() {
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
            for: ToolbarHelper().shouldShowTopTabs(for: traitCollection)
        )

        completion(timingToMatchGradientOverlay)
    }

    func tabToolbarDidPressLibrary(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
    }

    func dismissUrlBar() {
        if isToolbarRefactorEnabled, addressToolbarContainer.inOverlayMode {
            addressToolbarContainer.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        } else if !isToolbarRefactorEnabled, urlBar.inOverlayMode {
            urlBar.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        }
    }

    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        didTapOnBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        handleTabToolBarDidLongPressForwardOrBack()
    }

    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        didTapOnForward()
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
        didTapOnMenu(button: button)
    }

    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        updateZoomPageBarVisibility(visible: false)
        focusOnTabSegment()
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
        let newTab = getNewTabAction()
        let newPrivateTab = getNewPrivateTabAction()
        let closeTab = getCloseTabAction()

        if let tab = self.tabManager.selectedTab {
            return tab.isPrivate ? [newPrivateTab, closeTab] : [newTab, closeTab]
        }

        return [newTab, closeTab]
    }

    func getTabToolbarRefactorLongPressActions() -> [[PhotonRowActions]] {
        let newTab = getNewTabAction()
        let newPrivateTab = getNewPrivateTabAction()
        let closeTab = getCloseTabAction()

        return [[newTab, newPrivateTab], [closeTab]]
    }

    func getNewTabLongPressActions() -> [[PhotonRowActions]] {
        let newTab = getNewTabAction()
        let newPrivateTab = getNewPrivateTabAction()

        return [[newTab, newPrivateTab]]
    }

    private func getNewTabAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .KeyboardShortcuts.NewTab,
                                     iconString: StandardImageIdentifiers.Large.plus,
                                     iconType: .Image) { _ in
            let shouldFocusLocationField = self.newTabSettings == .blankPage
            self.overlayManager.openNewTab(url: nil, newTabSettings: self.newTabSettings)
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false)
        }.items
    }

    private func getNewPrivateTabAction() -> PhotonRowActions {
        let isRefactorEnabled = isToolbarRefactorEnabled && isOneTapNewTabEnabled
        let iconString = isRefactorEnabled ? StandardImageIdentifiers.Large.privateMode : StandardImageIdentifiers.Large.plus
        return SingleActionViewModel(title: .KeyboardShortcuts.NewPrivateTab,
                                     iconString: iconString,
                                     iconType: .Image) { _ in
            let shouldFocusLocationField = self.newTabSettings == .blankPage
            self.overlayManager.openNewTab(url: nil, newTabSettings: self.newTabSettings)
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: true)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .newPrivateTab, value: .tabTray)
        }.items
    }

    private func getCloseTabAction() -> PhotonRowActions {
        let isRefactorEnabled = isToolbarRefactorEnabled && isOneTapNewTabEnabled
        let title = isRefactorEnabled ? String.Toolbars.TabToolbarLongPressActionsMenu.CloseThisTabButton :
                                        String.KeyboardShortcuts.CloseCurrentTab
        return SingleActionViewModel(title: title,
                                     iconString: StandardImageIdentifiers.Large.cross,
                                     iconType: .Image) { _ in
            if let tab = self.tabManager.selectedTab {
                self.tabManager.removeTab(tab)
                self.updateTabCountUsingTabManager(self.tabManager)
                self.showToast(message: .TabsTray.CloseTabsToast.SingleTabTitle, toastAction: .closeTab)
            }
        }.items
    }

    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        presentTabsLongPressAction(from: button)
    }

    func tabToolbarDidPressSearch(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        focusLocationTextField(forTab: tabManager.selectedTab)
    }
}

// MARK: - ToolbarActionMenuDelegate
extension BrowserViewController: ToolBarActionMenuDelegate, UIDocumentPickerDelegate {
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
        updateFindInPageVisibility(isVisible: true)
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

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            showToast(message: .LegacyAppMenu.AppMenuDownloadPDFConfirmMessage, toastAction: .downloadPDF)
        }
    }

    func showFilePicker(fileURL: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        showViewController(viewController: documentPicker)
    }
}
