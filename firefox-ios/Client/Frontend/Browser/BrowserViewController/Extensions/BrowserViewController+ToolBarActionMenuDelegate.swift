// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI
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
            // After a navigation double tap is detected we dispatch the action to show the hint
            store.dispatch(ToolbarModernAction.navigationHintAvailabilityChanged(canShow: true), forWindowUUID: windowUUID)
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
            actionOnDismiss: { [windowUUID] in
                // After the hint is dismissed reset the hint to false
                store.dispatch(ToolbarModernAction.navigationHintAvailabilityChanged(canShow: false),
                               forWindowUUID: windowUUID)
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
        // ToolbarModernAction.navigationHintAvailabilityChanged will have to be dispatched again through user action
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
            store.dispatch(ToolbarModernAction.navigationHintAvailabilityChanged(canShow: false),
                           forWindowUUID: windowUUID)
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

    func dismissGoogleLensTip() {
        googleLensTipObservationTask?.cancel()
        googleLensTipObservationTask = nil

        if let tipViewController = googleLensTipViewController,
           presentedViewController === tipViewController {
            dismiss(animated: true)
        }
        googleLensTipViewController = nil
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
            if TabGroupsFeatureFlag.isEnabled { return makeTabsLongPressMenu() }
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
                UIPasteboard.general.asyncString { pasteboardContents in
                    guard let pasteboardContents else { return }
                    ensureMainThread {
                        self?.addressToolbarContainer.performAfterContextMenuDismissal {
                            self?.addressToolbarContainer.delegate?.openBrowser(searchTerm: pasteboardContents)
                        }
                    }
                }
            }
            pasteAndGoAction.accessibilityIdentifier = AccessibilityIdentifiers.Photon.pasteAndGoAction
            actions.append(pasteAndGoAction)

            let pasteAction = UIAction(
                title: .PasteTitle,
                image: UIImage(named: StandardImageIdentifiers.Large.clipboard)?.withRenderingMode(.alwaysTemplate)
            ) { [weak self] _ in
                UIPasteboard.general.asyncString { pasteboardContents in
                    guard let pasteboardContents else { return }
                    ensureMainThread {
                        self?.addressToolbarContainer.performAfterContextMenuDismissal {
                            self?.addressToolbarContainer.enterOverlayMode(pasteboardContents, pasted: true, search: true)
                        }
                    }
                }
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
        ) { [weak self] _ in
            self?.closeCurrentTabFromToolbar()
        }
        action.accessibilityIdentifier = StandardImageIdentifiers.Large.cross
        return action
    }

    func makeTabsLongPressMenu() -> UIMenu {
        guard TabGroupsFeatureFlag.isEnabled, tabManager.selectedTab?.isPrivate == false else {
            return legacyTabsLongPressMenu()
        }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: tabManager)
        let creation = UIMenu(options: .displayInline, children: [getNewTabAction(), getNewPrivateTabAction()])
        let groupActions: [UIMenuElement]
        if controller.state.groups.isEmpty {
            groupActions = [newToolbarGroupAction(movingCurrentTab: true)]
        } else {
            groupActions = [toolbarGroupDestinations(controller: controller, movingCurrentTab: false),
                            toolbarGroupDestinations(controller: controller, movingCurrentTab: true)]
        }
        let visibleTabs = TabGroupsSessionStore.visibleNormalTabs(tabManager.normalTabs, for: windowUUID)
        let attributes: UIMenuElement.Attributes = visibleTabs.isEmpty ? [.destructive, .disabled] : .destructive
        let closeAll = UIAction(title: String(format: .TabGroups.CloseAllTabs, String(visibleTabs.count)),
                                image: UIImage(systemName: "xmark"),
                                identifier: UIAction.Identifier("tabGroupsToolbar.closeAllTabs"),
                                attributes: attributes) { [weak self] _ in
            guard TabGroupsFeatureFlag.isEnabled,
                  let self,
                  self.tabManager.selectedTab?.isPrivate == false else { return }
            let tabs = TabGroupsSessionStore.visibleNormalTabs(self.tabManager.normalTabs, for: self.windowUUID)
            TabGroupsTabActions(controller: controller, tabManager: self.tabManager).closeTabs(tabs)
            self.updateTabCountUsingTabManager(self.tabManager)
        }
        return UIMenu(children: [creation,
                                 UIMenu(options: .displayInline, children: groupActions),
                                 UIMenu(options: .displayInline, children: [closeAll, getCloseTabAction()])])
    }

    private func legacyTabsLongPressMenu() -> UIMenu {
        UIMenu(children: [
            UIMenu(options: .displayInline, children: [getNewTabAction(), getNewPrivateTabAction()]),
            UIMenu(options: .displayInline, children: [getCloseTabAction()])
        ])
    }

    private func toolbarGroupDestinations(controller: TabGroupsController, movingCurrentTab: Bool) -> UIMenu {
        let currentGroupID = movingCurrentTab ? tabManager.selectedTab?.groupID : controller.state.selectedGroupID
        let ungroupedCount = tabManager.normalTabs.filter { $0.groupID == nil }.count
        let ungroupedTitle = ungroupedCount == 1
            ? "1 Tab"
            : String(format: "%@ Tabs", String(ungroupedCount))
        let ungrouped = UIAction(title: ungroupedTitle,
                                 image: UIImage(named: StandardImageIdentifiers.Large.deviceMobile),
                                 state: currentGroupID == nil ? .on : .off) { [weak self] _ in
            guard TabGroupsFeatureFlag.isEnabled else { return }
            if movingCurrentTab {
                self?.moveCurrentTabToGroup(nil)
            } else {
                self?.switchToToolbarGroup(nil)
            }
        }
        let groups: [UIMenuElement] = controller.state.groups.map { group in
            UIAction(title: group.title,
                     image: group.icon.badgeImage(color: TabGroupColorPalette.adaptiveColor(for: group.color)),
                     attributes: movingCurrentTab && !controller.canMoveTabs(to: group.id) ? .disabled : [],
                     state: currentGroupID == group.id ? .on : .off) { [weak self] _ in
                guard TabGroupsFeatureFlag.isEnabled else { return }
                if movingCurrentTab {
                    self?.moveCurrentTabToGroup(group.id)
                } else {
                    self?.switchToToolbarGroup(group.id)
                }
            }
        }
        let title = movingCurrentTab ? String.TabGroups.MoveToTabGroup : String.TabGroups.SwitchTabGroups
        let identifier = movingCurrentTab ? "tabGroupsToolbar.moveToGroup" : "tabGroupsToolbar.switchGroups"
        return UIMenu(title: title,
                      image: UIImage(systemName: movingCurrentTab ? "arrow.up.forward.square" : "square.on.square"),
                      identifier: UIMenu.Identifier(identifier),
                      children: [UIMenu(options: .displayInline, children: [ungrouped]),
                                 UIMenu(options: .displayInline, children: groups),
                                 UIMenu(options: .displayInline,
                                        children: [newToolbarGroupAction(movingCurrentTab: movingCurrentTab)])])
    }

    private func newToolbarGroupAction(movingCurrentTab: Bool) -> UIAction {
        let tabID = movingCurrentTab ? tabManager.selectedTab?.tabUUID : nil
        let hasGroups = !TabGroupsSessionStore.controller(for: windowUUID, tabManager: tabManager).state.groups.isEmpty
        let title = movingCurrentTab && !hasGroups
            ? String.TabGroups.MoveToNewTabGroup : String.TabGroups.NewTabGroupMenu
        return UIAction(title: title,
                        image: UIImage(systemName: "plus.square.on.square"),
                        identifier: UIAction.Identifier("tabGroupsToolbar.newGroup")) { [weak self] _ in
            guard TabGroupsFeatureFlag.isEnabled else { return }
            self?.showNewTabGroupEditor(movingTabID: tabID)
        }
    }

    func showNewTabGroupEditor(url: URL? = nil, movingTabID: TabUUID? = nil) {
        guard TabGroupsFeatureFlag.isEnabled,
              tabManager.selectedTab?.isPrivate != true,
              presentedViewController == nil else { return }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: tabManager)
        let editor = TabGroupEditorView(windowUUID: windowUUID,
                                        themeManager: themeManager,
                                        onCancel: { [weak self] in self?.dismiss(animated: true) }
        ) { [weak self] name, icon, color in
            guard TabGroupsFeatureFlag.isEnabled, let self else { return }
            let tabIDs = movingTabID.map { [$0] } ?? []
            if let movingTabID {
                guard let tab = self.tabManager.getTabForUUID(uuid: movingTabID), !tab.isPrivate else { return }
            }
            let normalIDs = self.tabManager.normalTabs.map(\.tabUUID)
            guard let groupID = controller.createGroup(name: name,
                                                       icon: icon,
                                                       color: color,
                                                       tabIDs: tabIDs,
                                                       normalTabIDs: normalIDs) else { return }
            let tab = movingTabID.flatMap { self.tabManager.getTabForUUID(uuid: $0) }
                ?? self.tabManager.addTab(url.map { URLRequest(url: $0) }, isPrivate: false, groupID: groupID)
            self.tabManager.selectTab(tab)
            controller.recordSelectedTab(tab.tabUUID, normalTabIDs: self.tabManager.normalTabs.map(\.tabUUID))
            self.dismiss(animated: true)
            self.updateTabCountUsingTabManager(self.tabManager)
        }
        let host = UIHostingController(rootView: editor)
        host.modalPresentationStyle = .pageSheet
        host.sheetPresentationController?.detents = [.large()]
        present(host, animated: true)
    }

    func openLinkInTabGroup(url: URL, groupID: TabGroupID?) {
        guard TabGroupsFeatureFlag.isEnabled, tabManager.selectedTab?.isPrivate != true else { return }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: tabManager)
        Task { [weak self] in
            guard let self, TabGroupsFeatureFlag.isEnabled else { return }
            do {
                let host = try await TabGroupsTabActions(controller: controller, tabManager: self.tabManager)
                    .openGroup(groupID)
                guard TabGroupsFeatureFlag.isEnabled else { return }
                let windows: WindowManager = AppContainer.shared.resolve()
                guard let manager = host == self.windowUUID ? self.tabManager : windows.windows[host]?.tabManager else {
                    return
                }
                let hostController = TabGroupsSessionStore.controller(for: host, tabManager: manager)
                hostController.selectGroup(id: groupID)
                let tab = manager.addTab(URLRequest(url: url), isPrivate: false, groupID: groupID)
                manager.selectTab(tab)
                hostController.recordSelectedTab(tab.tabUUID, normalTabIDs: manager.normalTabs.map(\.tabUUID))
                if host == self.windowUUID {
                    self.updateTabCountUsingTabManager(manager)
                } else {
                    try await activateTabGroupWindow(host, groupID: groupID)
                }
            } catch {
                DefaultLogger.shared.log("Could not open link in tab group: \(error)", level: .warning, category: .tabs)
            }
        }
    }

    private func switchToToolbarGroup(_ groupID: UUID?) {
        guard TabGroupsFeatureFlag.isEnabled, tabManager.selectedTab?.isPrivate != true else { return }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: tabManager)
        Task { [weak self] in
            guard let self else { return }
            do {
                let host = try await TabGroupsTabActions(controller: controller, tabManager: self.tabManager)
                    .openGroup(groupID)
                guard TabGroupsFeatureFlag.isEnabled else { return }
                guard host == self.windowUUID else {
                    try await activateTabGroupWindow(host, groupID: groupID)
                    return
                }
                let ids = self.tabManager.normalTabs.map(\.tabUUID)
                if let id = controller.preferredTabID(normalTabIDs: ids),
                   let tab = self.tabManager.getTabForUUID(uuid: id) {
                    self.tabManager.selectTab(tab)
                    controller.recordSelectedTab(id, normalTabIDs: ids)
                } else {
                    self.openBlankNewTab(focusLocationField: false)
                }
                self.updateTabCountUsingTabManager(self.tabManager)
            } catch {
                DefaultLogger.shared.log("Could not open tab group: \(error)", level: .warning, category: .tabs)
            }
        }
    }

    private func moveCurrentTabToGroup(_ groupID: UUID?) {
        guard TabGroupsFeatureFlag.isEnabled, let tab = tabManager.selectedTab, !tab.isPrivate else { return }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: tabManager)
        guard controller.canMoveTabs(to: groupID) else { return }
        TabGroupsTabActions(controller: controller, tabManager: tabManager).moveTab(tab.tabUUID, to: groupID)
        updateTabCountUsingTabManager(tabManager)
    }

    private func closeCurrentTabFromToolbar() {
        guard let tab = tabManager.selectedTab else { return }
        tabsPanelTelemetry.tabClosed(mode: tab.isPrivate ? .private : .normal)
        if TabGroupsFeatureFlag.isEnabled, !tab.isPrivate {
            let controller = TabGroupsSessionStore.controller(for: windowUUID)
            TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tab])
        } else {
            tabManager.removeTab(tab.tabUUID)
        }
        let action = GeneralBrowserAction(windowUUID: windowUUID,
                                          actionType: GeneralBrowserActionType.didCloseTabFromToolbar)
        store.dispatch(action)
        updateTabCountUsingTabManager(tabManager)
    }
}
