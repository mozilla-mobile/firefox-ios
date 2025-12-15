// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

extension BrowserViewController: PhotonActionSheetProtocol {
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
            withArrowDirection: toolbarHelper.shouldShowNavigationToolbar(for: traitCollection) ? .down : .up,
            andDelegate: self,
            presentedUsing: { [weak self] in
                self?.presentContextualHint(for: .dataClearance)
            },
            andActionForButton: { },
            overlayState: overlayManager)
    }

    private func presentDataClearanceContextualHint() {
        present(dataClearanceContextHintVC, animated: true)
        UIAccessibility.post(notification: .layoutChanged, argument: dataClearanceContextHintVC)
    }

    // Starts a timer to monitor for a navigation button double tap for the navigation contextual hint
    @MainActor
    func startNavigationButtonDoubleTapTimer() {
        guard isToolbarNavigationHintEnabled else { return }
        if navigationHintDoubleTapTimer == nil {
            navigationHintDoubleTapTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                ensureMainThread {
                    self.navigationHintDoubleTapTimer = nil
                }
            }
        } else {
            navigationHintDoubleTapTimer = nil
            let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.navigationButtonDoubleTapped)
            store.dispatch(action)
        }
    }

    func configureNavigationContextualHint(_ view: UIView) {
        navigationContextHintVC.configure(
            anchor: view,
            withArrowDirection: toolbarHelper.shouldShowNavigationToolbar(for: traitCollection) ? .down : .up,
            andDelegate: self,
            presentedUsing: { [weak self] in
                self?.presentContextualHint(for: .navigation)
            },
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
            selectedTab.isFxHomeTab || !selectedTab.isLoading,
            !state.microsurveyState.showPrompt {
            present(navigationContextHintVC, animated: true)
            UIAccessibility.post(notification: .layoutChanged, argument: navigationContextHintVC)
        } else {
            let action = ToolbarAction(windowUUID: self.windowUUID,
                                       actionType: ToolbarActionType.navigationHintFinishedPresenting)
            store.dispatch(action)
        }
    }

    func configureToolbarUpdateContextualHint(addressToolbarView: UIView, navigationToolbarView: UIView) {
        guard let state = store.state.screenState(ToolbarState.self,
                                                  for: .toolbar,
                                                  window: windowUUID),
              isToolbarUpdateHintEnabled
        else { return }

        let showNavToolbar = toolbarHelper.shouldShowNavigationToolbar(for: traitCollection)
        let view = state.toolbarPosition == .top && showNavToolbar ? navigationToolbarView : addressToolbarView
        let arrowDirection: UIPopoverArrowDirection = state.toolbarPosition == .top && !showNavToolbar ? .up : .down

        toolbarUpdateContextHintVC.configure(
            anchor: view,
            withArrowDirection: arrowDirection,
            andDelegate: self,
            presentedUsing: { [weak self] in
                self?.presentContextualHint(for: .toolbarUpdate)
            },
            andActionForButton: { },
            overlayState: overlayManager)
    }

    private func presentToolbarUpdateContextualHint() {
        guard !IntroScreenManager(prefs: profile.prefs).shouldShowIntroScreen,
              let selectedTab = tabManager.selectedTab,
              selectedTab.isFxHomeTab || selectedTab.isCustomHomeTab
        else { return }

        present(toolbarUpdateContextHintVC, animated: true)
        UIAccessibility.post(notification: .layoutChanged, argument: toolbarUpdateContextHintVC)
    }

    // MARK: - Summarize CFR / Contextual Hint
    func configureSummarizeToolbarEntryContextualHint(for view: UIView) {
        guard let state = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID) else { return }
        // Show up arrow for iPad and landscape or top address bar; otherwise show down arrow
        let showNavToolbar = toolbarHelper.shouldShowNavigationToolbar(for: traitCollection)
        let shouldShowUpArrow = state.toolbarPosition == .top || !showNavToolbar

        summarizeToolbarEntryContextHintVC.configure(
            anchor: view,
            withArrowDirection: shouldShowUpArrow ? .up : .down,
            andDelegate: self,
            presentedUsing: { [weak self] in
                self?.presentContextualHint(for: .summarizeToolbarEntry)
            },
            andActionForButton: { },
            overlayState: overlayManager)
    }

    private func presentSummarizeToolbarEntryContextualHint() {
        present(summarizeToolbarEntryContextHintVC, animated: true)
        UIAccessibility.post(notification: .layoutChanged, argument: summarizeToolbarEntryContextHintVC)
    }

    // Reset the CFR timer for the data clearance button to avoid presenting the CFR
    // In cases, such as if user navigates to homepage
    func resetSummarizeToolbarCFRTimer() {
        summarizeToolbarEntryContextHintVC.stopTimer()
    }

    // MARK: - Translation CFR
    func configureTranslationContextualHint(for view: UIView) {
        guard let state = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID) else { return }
        // Show up arrow for iPad and landscape or top address bar; otherwise show down arrow
        let showNavToolbar = toolbarHelper.shouldShowNavigationToolbar(for: traitCollection)
        let shouldShowUpArrow = state.toolbarPosition == .top || !showNavToolbar

        translationContextHintVC.configure(
            anchor: view,
            withArrowDirection: shouldShowUpArrow ? .up : .down,
            andDelegate: self,
            presentedUsing: { [weak self] in
                self?.presentContextualHint(for: .translation)
            },
            andActionForButton: { },
            overlayState: overlayManager)
    }

    private func presentTranslationContextualHint() {
        present(translationContextHintVC, animated: true)
        UIAccessibility.post(notification: .layoutChanged, argument: translationContextHintVC)
    }

    private func presentContextualHint(for hintType: ContextualHintType) {
        scrollController.showToolbars(animated: true)
        switch hintType {
        case .summarizeToolbarEntry: presentSummarizeToolbarEntryContextualHint()
        case .translation: presentTranslationContextualHint()
        case .dataClearance: presentDataClearanceContextualHint()
        case .navigation: presentNavigationContextualHint()
        case .toolbarUpdate: presentToolbarUpdateContextualHint()
        default: break
        }
    }

    func dismissToolbarCFRs(with windowUUID: WindowUUID) {
        guard let toolbarState = store.state.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: windowUUID
        ) else {
            return
        }
        let translationAction = toolbarState.addressToolbar.leadingPageActions.first(where: { $0.actionType == .translate })
        if translationAction == nil {
            resetTranslationCFRTimer()
        }
    }

    func resetCFRsTimer() {
        resetDataClearanceCFRTimer()
        resetSummarizeToolbarCFRTimer()
    }

    // Reset the CFR timer for the translation button to avoid presenting the CFR
    // In cases, such as if translation icon is not available
    private func resetTranslationCFRTimer() {
        translationContextHintVC.stopTimer()
    }

    /// Triggers clearing the users private session data, an alert is shown once and then, deletion is done directly after
    func didTapOnDataClearance() {
        guard !(profile.prefs.boolForKey(PrefsKeys.dataClearanceAlertShown) ?? false) else {
            performDeletionAction()
            return
        }

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
                self?.performDeletionAction()
            }
        )

        alert.addAction(deleteDataAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) { [weak self] in
            self?.profile.prefs.setBool(true, forKey: PrefsKeys.dataClearanceAlertShown)
        }
    }

    private func performDeletionAction() {
        self.privateBrowsingTelemetry.sendDataClearanceTappedTelemetry(didConfirm: true)
        self.setupDataClearanceAnimation { timingConstant in
            DispatchQueue.main.asyncAfter(deadline: .now() + timingConstant) {
                self.closePrivateTabsAndOpenNewPrivateHomepage()
            }
        }
    }

    private func closePrivateTabsAndOpenNewPrivateHomepage() {
        tabManager.removeTabs(tabManager.privateTabs)
        tabManager.selectTab(tabManager.addTab(isPrivate: true))
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
            for: toolbarHelper.shouldShowTopTabs(for: traitCollection)
        )

        completion(timingToMatchGradientOverlay)
    }

    func dismissUrlBar() {
        if addressToolbarContainer.inOverlayMode {
            addressToolbarContainer.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        }
    }

    func getNavigationToolbarLongPressActionsForModeSwitching() -> [PhotonRowActions] {
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

    func getMoreNavigationToolbarLongPressActions() -> [PhotonRowActions] {
        let newTab = getNewTabAction()
        let newPrivateTab = getNewPrivateTabAction()
        let closeTab = getCloseTabAction()

        if let tab = self.tabManager.selectedTab {
            return tab.isPrivate ? [newPrivateTab, closeTab] : [newTab, closeTab]
        }

        return [newTab, closeTab]
    }

    func getNavigationToolbarRefactorLongPressActions() -> [[PhotonRowActions]] {
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
        let iconString = isOneTapNewTabEnabled ? StandardImageIdentifiers.Large.privateMode :
                                                StandardImageIdentifiers.Large.plus
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
        let title = isOneTapNewTabEnabled ? String.Toolbars.TabToolbarLongPressActionsMenu.CloseThisTabButton :
                                            String.KeyboardShortcuts.CloseCurrentTab
        return SingleActionViewModel(title: title,
                                     iconString: StandardImageIdentifiers.Large.cross,
                                     iconType: .Image) { _ in
            if let tab = self.tabManager.selectedTab {
                self.tabsPanelTelemetry.tabClosed(mode: tab.isPrivate ? .private : .normal)
                self.tabManager.removeTab(tab.tabUUID)
                store.dispatch(
                    GeneralBrowserAction(
                        windowUUID: self.windowUUID,
                        actionType: GeneralBrowserActionType.didCloseTabFromToolbar
                    )
                )
                self.updateTabCountUsingTabManager(self.tabManager)

                if !self.featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
                    || UIDevice.current.userInterfaceIdiom == .pad {
                    self.showToast(message: .TabsTray.CloseTabsToast.SingleTabTitle, toastAction: .closeTab)
                }
            }
        }.items
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

    func showToast(_ urlString: String? = nil, _ title: String?, message: String, toastAction: MenuButtonToastAction) {
        switch toastAction {
        case .bookmarkPage:
            let viewModel = ButtonToastViewModel(labelText: message,
                                                 buttonText: .BookmarksEdit)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme()) { isButtonTapped in
                isButtonTapped ? self.openBookmarkEditPanel(urlString: urlString) : nil
            }
            show(toast: toast, duration: DispatchTimeInterval.milliseconds(8000))
        case .removeBookmark:
            let viewModel = ButtonToastViewModel(labelText: message,
                                                 buttonText: .UndoString)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme()) { [weak self] isButtonTapped in
                guard let self, let currentTab = tabManager.selectedTab else { return }
                isButtonTapped ? self.addBookmark(
                    urlString: urlString ?? currentTab.url?.absoluteString ?? "",
                    title: title ?? currentTab.title
                ) : nil
            }
            show(toast: toast)
        case .closeTab:
            let viewModel = ButtonToastViewModel(labelText: message,
                                                 buttonText: .UndoString)
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

    func showEditBookmark() {
        guard let urlString = tabManager.selectedTab?.url?.absoluteString else { return }
        openBookmarkEditPanel(urlString: urlString)
    }

    func showTrackingProtection() {
        store.dispatch(
            GeneralBrowserAction(
                windowUUID: windowUUID,
                actionType: GeneralBrowserActionType.showTrackingProtectionDetails
            )
        )
    }
}
