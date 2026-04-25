// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

extension BrowserViewController: PhotonActionSheetProtocol {
    // Starts a timer to monitor for a navigation button double tap for the navigation contextual hint
    @MainActor
    func startNavigationButtonDoubleTapTimer() {
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
        guard let state = store.state.componentState(BrowserViewControllerState.self,
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
        guard let state = store.state.componentState(ToolbarState.self,
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
        guard let state = store.state.componentState(ToolbarState.self, for: .toolbar, window: windowUUID) else { return }
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
        guard let state = store.state.componentState(ToolbarState.self, for: .toolbar, window: windowUUID) else { return }
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
        case .navigation: presentNavigationContextualHint()
        case .toolbarUpdate: presentToolbarUpdateContextualHint()
        default: break
        }
    }

    func dismissToolbarCFRs(with windowUUID: WindowUUID) {
        guard let toolbarState = store.state.componentState(
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
        resetSummarizeToolbarCFRTimer()
    }

    // Reset the CFR timer for the translation button to avoid presenting the CFR
    // In cases, such as if translation icon is not available
    private func resetTranslationCFRTimer() {
        translationContextHintVC.stopTimer()
    }

    func dismissUrlBar() {
        if addressToolbarContainer.inOverlayMode {
            addressToolbarContainer.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        }
    }

    func getNavigationToolbarLongPressActions() -> [[PhotonRowActions]] {
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
        return SingleActionViewModel(title: .KeyboardShortcuts.NewPrivateTab,
                                     iconString: StandardImageIdentifiers.Large.privateMode,
                                     iconType: .Image) { _ in
            let shouldFocusLocationField = self.newTabSettings == .blankPage
            self.overlayManager.openNewTab(url: nil, newTabSettings: self.newTabSettings)
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: true)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .newPrivateTab, value: .tabTray)
        }.items
    }

    private func getCloseTabAction() -> PhotonRowActions {
        return SingleActionViewModel(title: String.Toolbars.TabToolbarLongPressActionsMenu.CloseThisTabButton,
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
            }
        }.items
    }
}
