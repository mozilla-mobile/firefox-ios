// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit

// Naming functions: use the suffix 'KeyCommand' for an additional level of namespacing (bug 1415830)
extension BrowserViewController {
    fileprivate typealias shortcuts = String.KeyboardShortcuts

    @objc private func openSettingsKeyCommand() {
        openSettings()
    }

    @objc private func showHistoryKeyCommand() {
        showPanel(.history)
    }

    @objc private func showDownloadsKeyCommand() {
        showPanel(.downloads)
    }

    @objc private func showBookmarksKeyCommand() {
        showPanel(.bookmarks)
    }

    private func showPanel(_ panel: LibraryPanelType) {
        guard let libraryViewController = self.libraryViewController else {
            showLibrary(panel: panel)
            return
        }

        libraryViewController.selectedPanel = panel
    }

    @objc private func openClearHistoryPanelKeyCommand() {
        guard let libraryViewController = self.libraryViewController else {
            let clearHistoryHelper = ClearHistoryHelper(profile: profile)
            clearHistoryHelper.showClearRecentHistory(onViewController: self, didComplete: {})
            return
        }

        libraryViewController.selectedPanel = .history
        NotificationCenter.default.post(name: .OpenClearRecentHistory, object: nil)
    }

    @objc private func addBookmarkKeyCommand() {
        if let tab = tabManager.selectedTab, firefoxHomeViewController == nil {
            guard let url = tab.canonicalURL?.displayURL else { return }
            addBookmark(url: url.absoluteString, title: tab.title, favicon: tab.displayFavicon)
        }
    }

    @objc private func reloadTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "reload"])

        if let tab = tabManager.selectedTab, firefoxHomeViewController == nil {
            tab.reload()
        }
    }

    @objc private func goBackKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "go-back"])

        if let tab = tabManager.selectedTab, tab.canGoBack, firefoxHomeViewController == nil {
            tab.goBack()
        }
    }

    @objc private func goForwardKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "go-forward"])

        if let tab = tabManager.selectedTab, tab.canGoForward {
            tab.goForward()
        }
    }

    @objc private func findInPageKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "find-in-page"])
        findInPage(withText: "")
    }

    @objc private func findInPageAgainKeyCommand() {
        findInPage(withText: FindInPageBar.retrieveSavedText ?? "")
    }

    private func findInPage(withText text: String) {
        if let tab = tabManager.selectedTab, firefoxHomeViewController == nil {
            self.tab(tab, didSelectFindInPageForSelection: text)
        }
    }

    @objc private func selectLocationBarKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "select-location-bar"])
        scrollController.showToolbars(animated: true)
        urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
    }

    @objc private func newTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "new-tab"])
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
    }

    @objc private func newPrivateTabKeyCommand() {
        // NOTE: We cannot and should not distinguish between "new-tab" and "new-private-tab"
        // when recording telemetry for key commands.
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "new-tab"])
        openBlankNewTab(focusLocationField: true, isPrivate: true)
        keyboardPressesHandler.reset()
    }

    @objc private func newNormalTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "new-tab"])
        openBlankNewTab(focusLocationField: true, isPrivate: false)
        keyboardPressesHandler.reset()
    }

    @objc private func closeTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "close-tab"])
        guard let currentTab = tabManager.selectedTab else {
            return
        }
        tabManager.removeTab(currentTab)
    }

    @objc private func undoLastTabClosedKeyCommand() {
        guard let lastClosedURL = profile.recentlyClosedTabs.popFirstTab()?.url,
                   let selectedTab = tabManager.selectedTab
        else { return }

        let request = URLRequest(url: lastClosedURL)
        let closedTab = tabManager.addTab(request, afterTab: selectedTab, isPrivate: false)
        tabManager.selectTab(closedTab)
    }

    @objc private func showTabTrayKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "show-tab-tray"])
        showTabTray()
    }

    @objc private func moveURLCompletionKeyCommand(sender: UIKeyCommand) {
        guard let searchController = self.searchController else { return }

        searchController.handleKeyCommands(sender: sender)
    }

    // MARK: - Tab selection

    @objc private func nextTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "next-tab"])
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.firstIndex(of: currentTab), index + 1 < tabs.count {
            tabManager.selectTab(tabs[index + 1])
        } else if let firstTab = tabs.first {
            tabManager.selectTab(firstTab)
        }

        keyboardPressesHandler.reset()
    }

    @objc private func previousTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .keyCommand,
                                     extras: ["action": "previous-tab"])
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.firstIndex(of: currentTab), index - 1 < tabs.count && index != 0 {
            tabManager.selectTab(tabs[index - 1])
        } else if let lastTab = tabs.last {
            tabManager.selectTab(lastTab)
        }

        keyboardPressesHandler.reset()
    }

    @objc private func selectFirstTab() {
        selectTab(number: 0)
    }

    @objc private func selectTabTwo() {
        selectTab(number: 1)
    }

    @objc private func selectTabThree() {
        selectTab(number: 2)
    }

    @objc private func selectTabFour() {
        selectTab(number: 3)
    }

    @objc private func selectTabFive() {
        selectTab(number: 4)
    }

    @objc private func selectTabSix() {
        selectTab(number: 5)
    }

    @objc private func selectTabSeven() {
        selectTab(number: 6)
    }

    @objc private func selectTabEight() {
        selectTab(number: 7)
    }

    @objc private func selectLastTab() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        selectTab(number: tabs.count - 1)
    }

    /// Select a certain tab number - If number is greater than the present number of tabs, select the last tab
    /// - Parameter number: The 0 indexed tab number to select
    private func selectTab(number: Int) {
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        // Do not continue if the index of the new tab to select is the current one
        guard let currentTabIndex = tabs.firstIndex(of: currentTab), currentTabIndex != number else {
            return
        }

        if tabs.count > number {
            tabManager.selectTab(tabs[number])
            keyboardPressesHandler.reset()
        } else if let lastTab = tabs.last {
            tabManager.selectTab(lastTab)
            keyboardPressesHandler.reset()
        }
    }

    // MARK: Zoom

    @objc private func zoomIn() {
        guard let currentTab = tabManager.selectedTab,
              firefoxHomeViewController == nil else { return }

        currentTab.zoomIn()
    }

    @objc private func zoomOut() {
        guard let currentTab = tabManager.selectedTab,
              firefoxHomeViewController == nil else { return }

        currentTab.zoomOut()
    }

    @objc private func resetZoom() {
        guard let currentTab = tabManager.selectedTab,
              firefoxHomeViewController == nil else { return }

        currentTab.resetZoom()
    }

    // MARK: - KeyCommands

    override var keyCommands: [UIKeyCommand]? {
        let searchLocationCommands = [
            // Navigate the suggestions
            UIKeyCommand(action: #selector(moveURLCompletionKeyCommand(sender:)), input: UIKeyCommand.inputDownArrow),
            UIKeyCommand(action: #selector(moveURLCompletionKeyCommand(sender:)), input: UIKeyCommand.inputUpArrow),
        ]

        let overridesTextEditing = [
            UIKeyCommand(action: #selector(nextTabKeyCommand), input: UIKeyCommand.inputRightArrow, modifierFlags: [.command, .shift]),
            UIKeyCommand(action: #selector(previousTabKeyCommand), input: UIKeyCommand.inputLeftArrow, modifierFlags: [.command, .shift]),
            UIKeyCommand(action: #selector(goBackKeyCommand), input: UIKeyCommand.inputLeftArrow, modifierFlags: .command),
            UIKeyCommand(action: #selector(goForwardKeyCommand), input: UIKeyCommand.inputRightArrow, modifierFlags: .command),
        ]

        let windowShortcuts = [
            UIKeyCommand(action: #selector(nextTabKeyCommand), input: "\t", modifierFlags: .control, discoverabilityTitle: shortcuts.ShowNextTab),
            UIKeyCommand(action: #selector(previousTabKeyCommand), input: "\t", modifierFlags: [.control, .shift], discoverabilityTitle: shortcuts.ShowPreviousTab),
            UIKeyCommand(action: #selector(nextTabKeyCommand), input: "]", modifierFlags: [.command, .shift]),
            UIKeyCommand(action: #selector(previousTabKeyCommand), input: "[", modifierFlags: [.command, .shift]),
            UIKeyCommand(action: #selector(showTabTrayKeyCommand), input: "\t", modifierFlags: [.command, .alternate], discoverabilityTitle: shortcuts.ShowTabTray),
            UIKeyCommand(action: #selector(showTabTrayKeyCommand), input: "\\", modifierFlags: [.command, .shift]),
        ]

        // In iOS 15+, certain keys events are delivered to the text input or focus systems first, unless specified otherwise
        if #available(iOS 15, *) {
            searchLocationCommands.forEach { $0.wantsPriorityOverSystemBehavior = true }
            overridesTextEditing.forEach { $0.wantsPriorityOverSystemBehavior = true }
            windowShortcuts.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }

        let commands = [
            // Settings
            UIKeyCommand(action: #selector(openSettingsKeyCommand), input: ",", modifierFlags: .command, discoverabilityTitle: shortcuts.Settings),

            // File
            UIKeyCommand(action: #selector(newTabKeyCommand), input: "t", modifierFlags: .command, discoverabilityTitle: shortcuts.NewTab),
            UIKeyCommand(action: #selector(selectLocationBarKeyCommand), input: "l", modifierFlags: .command, discoverabilityTitle: shortcuts.SelectLocationBar),
            UIKeyCommand(action: #selector(newPrivateTabKeyCommand), input: "p", modifierFlags: [.command, .shift], discoverabilityTitle: shortcuts.NewPrivateTab),
            UIKeyCommand(action: #selector(closeTabKeyCommand), input: "w", modifierFlags: .command, discoverabilityTitle: shortcuts.CloseCurrentTab),
            UIKeyCommand(action: #selector(undoLastTabClosedKeyCommand), input: "t", modifierFlags: [.command, .shift]),
            UIKeyCommand(action: #selector(newNormalTabKeyCommand), input: "n", modifierFlags: [.command, .shift]),

            // Edit
            UIKeyCommand(action: #selector(findInPageKeyCommand), input: "f", modifierFlags: .command, discoverabilityTitle: shortcuts.Find),
            UIKeyCommand(action: #selector(findInPageAgainKeyCommand), input: "g", modifierFlags: .command, discoverabilityTitle: shortcuts.FindAgain),

            // View
            UIKeyCommand(action: #selector(zoomIn), input: "+", modifierFlags: .command, discoverabilityTitle: shortcuts.ZoomIn),
            UIKeyCommand(action: #selector(zoomOut), input: "-", modifierFlags: .command, discoverabilityTitle: shortcuts.ZoomOut),
            UIKeyCommand(action: #selector(resetZoom), input: "0", modifierFlags: .command, discoverabilityTitle: shortcuts.ActualSize),
            UIKeyCommand(action: #selector(reloadTabKeyCommand), input: "r", modifierFlags: .command, discoverabilityTitle: shortcuts.ReloadPage),
            
            // History
            UIKeyCommand(action: #selector(goBackKeyCommand), input: "[", modifierFlags: .command, discoverabilityTitle: shortcuts.Back),
            UIKeyCommand(action: #selector(openClearHistoryPanelKeyCommand), input: "\u{8}", modifierFlags: [.shift, .command], discoverabilityTitle: shortcuts.ClearRecentHistory),
            UIKeyCommand(action: #selector(goForwardKeyCommand), input: "]", modifierFlags: .command, discoverabilityTitle: shortcuts.Forward),
            UIKeyCommand(action: #selector(showHistoryKeyCommand), input: "y", modifierFlags: .command, discoverabilityTitle: shortcuts.ShowHistory),
            
            // Bookmarks
            UIKeyCommand(action: #selector(showBookmarksKeyCommand), input: "o", modifierFlags: [.shift, .command], discoverabilityTitle: shortcuts.ShowBookmarks),
            UIKeyCommand(action: #selector(addBookmarkKeyCommand), input: "d", modifierFlags: .command, discoverabilityTitle: shortcuts.AddBookmark),

            // Tools
            UIKeyCommand(action: #selector(showDownloadsKeyCommand), input: "j", modifierFlags: .command, discoverabilityTitle: shortcuts.ShowDownloads),
            UIKeyCommand(action: #selector(selectFirstTab), input: "1", modifierFlags: .command, discoverabilityTitle: shortcuts.ShowFirstTab),
            UIKeyCommand(action: #selector(selectTabTwo), input: "2", modifierFlags: .command),
            UIKeyCommand(action: #selector(selectTabThree), input: "3", modifierFlags: .command),
            UIKeyCommand(action: #selector(selectTabFour), input: "4", modifierFlags: .command),
            UIKeyCommand(action: #selector(selectTabFive), input: "5", modifierFlags: .command),
            UIKeyCommand(action: #selector(selectTabSix), input: "6", modifierFlags: .command),
            UIKeyCommand(action: #selector(selectTabSeven), input: "7", modifierFlags: .command),
            UIKeyCommand(action: #selector(selectTabEight), input: "8", modifierFlags: .command),
            UIKeyCommand(action: #selector(selectLastTab), input: "9", modifierFlags: .command, discoverabilityTitle: shortcuts.ShowLastTab),

        ] + windowShortcuts

        let isEditingText = tabManager.selectedTab?.isEditing ?? false

        if urlBar.inOverlayMode {
            return commands + searchLocationCommands
        } else if !isEditingText {
            return commands + overridesTextEditing
        }
        return commands
    }

    // MARK: Keyboards + Link click shortcuts

    func navigateLinkShortcutIfNeeded(url: URL) -> Bool {
        var shouldCancelHandler = false

        // Open tab in background || Open in new tab
        if keyboardPressesHandler.isOnlyCmdPressed || keyboardPressesHandler.isCmdAndShiftPressed {
            guard let isPrivate = tabManager.selectedTab?.isPrivate else { return shouldCancelHandler }
            let selectNewTab = !keyboardPressesHandler.isOnlyCmdPressed && keyboardPressesHandler.isCmdAndShiftPressed
            homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
            shouldCancelHandler = true

        // Download Link
        } else if keyboardPressesHandler.isOnlyOptionPressed, let currentTab = tabManager.selectedTab {
            // This checks if download is a blob, if yes, begin blob download process
            if !DownloadContentScript.requestBlobDownload(url: url, tab: currentTab) {
                // if not a blob, set pendingDownloadWebView and load the request in the webview, which will trigger the WKWebView navigationResponse delegate function and eventually downloadHelper.open()
                self.pendingDownloadWebView = currentTab.webView
                let request = URLRequest(url: url)
                currentTab.webView?.load(request)
            }
            shouldCancelHandler = true
        }

        return shouldCancelHandler
    }
}
