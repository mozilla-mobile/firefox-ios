// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import TipKit
import UIKit

extension BrowserViewController {
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

    @MainActor
    func configureGoogleLensTip(for button: UIButton) {
        guard #available(iOS 17.0, *),
              googleLensTipViewController == nil else { return }

        googleLensTipObservationTask?.cancel()
        googleLensTipObservationTask = Task { @MainActor [weak self, weak button] in
            let tip = GoogleLensTip()

            for await status in tip.statusUpdates {
                guard let self, !Task.isCancelled else { return }

                switch status {
                // Wait for TipKit to finish evaluating the tip's display eligibility.
                case .pending:
                    continue

                // Present the tip once TipKit determines it is eligible for display.
                case .available:
                    guard let button,
                          button.window != nil,
                          self.presentedViewController == nil,
                          let toolbarState = store.state.componentState(ToolbarState.self,
                                                                        for: .toolbar,
                                                                        window: self.windowUUID)
                    else { return }

                    let tipViewController = TipUIPopoverViewController(tip, sourceItem: button)
                    tipViewController.popoverPresentationController?.permittedArrowDirections =
                        toolbarState.toolbarPosition == .bottom ? .down : .up
                    self.googleLensTipViewController = tipViewController
                    self.present(tipViewController, animated: true)

                // Dismiss the presented tip when TipKit marks it as closed or otherwise invalid.
                case .invalidated:
                    guard let tipViewController = self.googleLensTipViewController else { return }
                    if self.presentedViewController === tipViewController {
                        self.dismiss(animated: true)
                    }
                    self.googleLensTipViewController = nil
                    return

                @unknown default:
                    break
                }
            }
        }
    }

    private func presentContextualHint(for hintType: ContextualHintType) {
        scrollController.showToolbars(animated: true)
        switch hintType {
        case .summarizeToolbarEntry: presentSummarizeToolbarEntryContextualHint()
        case .navigation: presentNavigationContextualHint()
        default: break
        }
    }

    func resetCFRsTimer() {
        resetSummarizeToolbarCFRTimer()
    }

    func dismissUrlBar() {
        if addressToolbarContainer.inOverlayMode {
            addressToolbarContainer.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        }
    }

    func contextMenu(for actionType: ToolbarActionConfiguration.ActionType) -> UIMenu? {
        switch actionType {
        case .locationView:
            let actions = getLocationBarActions()
            return actions.isEmpty
                ? nil
                : .init(children: [UIMenu(options: .displayInline, children: actions)])
        case .reload:
            guard let tab = tabManager.selectedTab else { return nil }
            let actions = getRefreshActions(for: tab)
            return actions.isEmpty ? nil : .init(children: [UIMenu(options: .displayInline, children: actions)])
        case .newTab:
            toolbarTelemetry.oneTapNewTabButtonLongPressed(isPrivate: tabManager.selectedTab?.isPrivate ?? false)
            return makeNewTabMenu()
        case .tabs:
            toolbarTelemetry.tabTrayButtonLongPressed(isPrivate: tabManager.selectedTab?.isPrivate ?? false)
            return .init(children: [
                UIMenu(options: .displayInline, children: [getNewTabAction(), getNewPrivateTabAction()]),
                UIMenu(options: .displayInline, children: [getCloseTabAction()])
            ])
        default:
            return nil
        }
    }

    func makeNewTabMenu() -> UIMenu {
        return .init(children: [
            UIMenu(options: .displayInline, children: [getNewTabAction(), getNewPrivateTabAction()])
        ])
    }

    private func getLocationBarActions() -> [UIAction] {
        var actions = [UIAction]()
        if UIPasteboard.general.hasStrings {
            let pasteAndGoAction = UIAction(
                title: .PasteAndGoTitle,
                image: UIImage(named: StandardImageIdentifiers.Large.clipboard)?.withRenderingMode(.alwaysTemplate)
            ) { [weak self] _ in
                guard let self, let pasteboardContents = UIPasteboard.general.string else { return }
                addressToolbarContainer.delegate?.openBrowser(searchTerm: pasteboardContents)
            }
            pasteAndGoAction.accessibilityIdentifier = AccessibilityIdentifiers.Photon.pasteAndGoAction
            actions.append(pasteAndGoAction)

            let pasteAction = UIAction(
                title: .PasteTitle,
                image: UIImage(named: StandardImageIdentifiers.Large.clipboard)?.withRenderingMode(.alwaysTemplate)
            ) { [weak self] _ in
                guard let self, let pasteboardContents = UIPasteboard.general.string else { return }
                addressToolbarContainer.enterOverlayMode(pasteboardContents, pasted: true, search: true)
            }
            pasteAction.accessibilityIdentifier = AccessibilityIdentifiers.Photon.pasteAction
            actions.append(pasteAction)
        }

        if tabManager.selectedTab?.canonicalURL?.displayURL != nil {
            let copyAddressAction = UIAction(
                title: .CopyAddressTitle,
                image: UIImage(named: StandardImageIdentifiers.Large.link)?.withRenderingMode(.alwaysTemplate)
            ) { [weak self] _ in
                let currentURL = self?.tabManager.selectedTab?.currentURL()
                if let url = self?.tabManager.selectedTab?.canonicalURL?.displayURL ?? currentURL {
                    UIPasteboard.general.url = url
                }
            }
            copyAddressAction.accessibilityIdentifier = AccessibilityIdentifiers.Photon.copyAddressAction
            actions.append(copyAddressAction)
        }
        return actions
    }

    private func getRefreshActions(for tab: Tab) -> [UIAction] {
        guard tab.webView?.url != nil,
              (tab.getContentScript(name: ReaderMode.name()) as? ReaderMode)?.state != .active
        else { return [] }

        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let toggleActionTitle: String
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent
                ? .LegacyAppMenu.AppMenuViewDesktopSiteTitleString
                : .LegacyAppMenu.AppMenuViewMobileSiteTitleString
        } else {
            toggleActionTitle = tab.changedUserAgent
                ? .LegacyAppMenu.AppMenuViewMobileSiteTitleString
                : .LegacyAppMenu.AppMenuViewDesktopSiteTitleString
        }

        let toggleDesktopSite = UIAction(
            title: toggleActionTitle,
            image: UIImage(named: StandardImageIdentifiers.Large.deviceDesktop)?.withRenderingMode(.alwaysTemplate)
        ) { _ in
            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(
                    forUrl: url,
                    isChangedUA: tab.changedUserAgent,
                    isPrivate: tab.isPrivate
                )
            }
        }
        toggleDesktopSite.accessibilityIdentifier = StandardImageIdentifiers.Large.deviceDesktop

        guard let url = tab.webView?.url,
              let helper = tab.contentBlocker,
              helper.isEnabled,
              helper.blockingStrengthPref == .strict
        else { return [toggleDesktopSite] }

        let isSafelisted = helper.status == .safelisted
        let title: String = isSafelisted ? .TrackingProtectionReloadWith : .TrackingProtectionReloadWithout
        let imageName = StandardImageIdentifiers.Large.shieldSlash
        let toggleTrackingProtection = UIAction(
            title: title,
            image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        ) { _ in
            ContentBlocker.shared.safelist(enable: !isSafelisted, url: url) {
                tab.reload()
            }
        }
        toggleTrackingProtection.accessibilityIdentifier = imageName
        return [toggleDesktopSite, toggleTrackingProtection]
    }

    private func getNewTabAction() -> UIAction {
        let action = UIAction(
            title: .KeyboardShortcuts.NewTab,
            image: UIImage(named: StandardImageIdentifiers.Large.plus)?.withRenderingMode(.alwaysTemplate)
        ) { _ in
            let shouldFocusLocationField = self.newTabSettings == .blankPage
            self.overlayManager.openNewTab(url: nil, newTabSettings: self.newTabSettings)
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false)
        }
        action.accessibilityIdentifier = StandardImageIdentifiers.Large.plus
        return action
    }

    private func getNewPrivateTabAction() -> UIAction {
        let action = UIAction(
            title: .KeyboardShortcuts.NewPrivateTab,
            image: UIImage(named: StandardImageIdentifiers.Large.privateMode)?.withRenderingMode(.alwaysTemplate)
        ) { _ in
            let shouldFocusLocationField = self.newTabSettings == .blankPage
            self.overlayManager.openNewTab(url: nil, newTabSettings: self.newTabSettings)
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: true)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .newPrivateTab, value: .tabTray)
        }
        action.accessibilityIdentifier = StandardImageIdentifiers.Large.privateMode
        return action
    }

    private func getCloseTabAction() -> UIAction {
        let action = UIAction(
            title: String.Toolbars.TabToolbarLongPressActionsMenu.CloseThisTabButton,
            image: UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            attributes: .destructive
        ) { _ in
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
        }
        action.accessibilityIdentifier = StandardImageIdentifiers.Large.cross
        return action
    }
}
