// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit

// Naming functions: use the suffix 'KeyCommand' for an additional level of namespacing (bug 1415830)
extension BrowserViewController {

    @objc private func showHistory() {
        showLibrary(panel: .history)
    }

    @objc private func showDownloads() {
        showLibrary(panel: .downloads)
    }

    @objc private func showBookmarks() {
        showLibrary(panel: .bookmarks)
    }

    @objc private func openClearHistoryPanel() {
        let clearHistoryHelper = ClearHistoryHelper(profile: profile)
        clearHistoryHelper.showClearRecentHistory(onViewController: self, didComplete: {})
    }

    @objc private func addCurrentTabToBookmarks() {
        if let tab = tabManager.selectedTab, firefoxHomeViewController == nil {
            guard let url = tab.canonicalURL?.displayURL else { return }
            addBookmark(url: url.absoluteString, title: tab.title, favicon: tab.displayFavicon)
        }
    }

    @objc private func reloadTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "reload"])
        if let tab = tabManager.selectedTab, firefoxHomeViewController == nil {
            tab.reload()
        }
    }

    @objc private func goBackKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "go-back"])
        if let tab = tabManager.selectedTab, tab.canGoBack, firefoxHomeViewController == nil {
            tab.goBack()
        }
    }

    @objc private func goForwardKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "go-forward"])
        if let tab = tabManager.selectedTab, tab.canGoForward {
            tab.goForward()
        }
    }

    @objc private func findInPageKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "find-in-page"])
        if let tab = tabManager.selectedTab, firefoxHomeViewController == nil {
            self.tab(tab, didSelectFindInPageForSelection: "")
        }
    }

    @objc private func selectLocationBarKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "select-location-bar"])
        scrollController.showToolbars(animated: true)
        urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
    }

    @objc private func newTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "new-tab"])
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
    }

    @objc private func newPrivateTabKeyCommand() {
        // NOTE: We cannot and should not distinguish between "new-tab" and "new-private-tab"
        // when recording telemetry for key commands.
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "new-tab"])
        openBlankNewTab(focusLocationField: true, isPrivate: true)
    }

    @objc private func closeTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "close-tab"])
        guard let currentTab = tabManager.selectedTab else {
            return
        }
        tabManager.removeTab(currentTab)
    }

    @objc private func nextTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "next-tab"])
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.firstIndex(of: currentTab), index + 1 < tabs.count {
            tabManager.selectTab(tabs[index + 1])
        } else if let firstTab = tabs.first {
            tabManager.selectTab(firstTab)
        }
    }

    @objc private func previousTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "previous-tab"])
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.firstIndex(of: currentTab), index - 1 < tabs.count && index != 0 {
            tabManager.selectTab(tabs[index - 1])
        } else if let lastTab = tabs.last {
            tabManager.selectTab(lastTab)
        }
    }

    @objc private func showTabTrayKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "show-tab-tray"])
        showTabTray()
    }

    @objc private func moveURLCompletionKeyCommand(sender: UIKeyCommand) {
        guard let searchController = self.searchController else {
            return
        }

        searchController.handleKeyCommands(sender: sender)
    }

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

        // In iOS 15+, certain keys events are delivered to the text input or focus systems first, unless specified otherwise
        if #available(iOS 15, *) {
            searchLocationCommands.forEach { $0.wantsPriorityOverSystemBehavior = true }
            overridesTextEditing.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }

        let commands = [
            // Settings
            // TODO: String KeyboardShortcuts.Settings
            UIKeyCommand(action: #selector(openSettings), input: ",", modifierFlags: .command, discoverabilityTitle: "Settings"),

            // File
            UIKeyCommand(action: #selector(newTabKeyCommand), input: "t", modifierFlags: .command, discoverabilityTitle: .NewTabTitle),
            UIKeyCommand(action: #selector(newPrivateTabKeyCommand), input: "p", modifierFlags: [.command, .shift], discoverabilityTitle: .NewPrivateTabTitle),
            UIKeyCommand(action: #selector(selectLocationBarKeyCommand), input: "l", modifierFlags: .command, discoverabilityTitle: .SelectLocationBarTitle),
            UIKeyCommand(action: #selector(closeTabKeyCommand), input: "w", modifierFlags: .command, discoverabilityTitle: .CloseTabTitle),
            // TODO: Save page as - Command + S

            // Edit
            UIKeyCommand(action: #selector(findInPageKeyCommand), input: "f", modifierFlags: .command, discoverabilityTitle: .FindTitle),
            // TODO: Find again - Command + G

            // View
            UIKeyCommand(action: #selector(reloadTabKeyCommand), input: "r", modifierFlags: .command, discoverabilityTitle: .ReloadPageTitle),
            // TODO: Zoom in - Command + +
            // TODO: Zoom out - Command + -
            // TODO: Actual size - Command + 0

            // History
            // TODO: String KeyboardShortcuts.ShowHistory & KeyboardShortcuts.ClearRecentHistory
            UIKeyCommand(action: #selector(showHistory), input: "y", modifierFlags: .command, discoverabilityTitle: "Show History"),
            UIKeyCommand(action: #selector(goBackKeyCommand), input: "[", modifierFlags: .command, discoverabilityTitle: .BackTitle),
            UIKeyCommand(action: #selector(goForwardKeyCommand), input: "]", modifierFlags: .command, discoverabilityTitle: .ForwardTitle),
            UIKeyCommand(action: #selector(openClearHistoryPanel), input: "\u{8}", modifierFlags: [.shift, .command], discoverabilityTitle: "Clear history"),

            // Bookmarks
            // TODO: String KeyboardShortcuts.ShowBookmarks & KeyboardShortcuts.AddBookmark
            UIKeyCommand(action: #selector(showBookmarks), input: "o", modifierFlags: [.shift, .command], discoverabilityTitle: "Show Bookmarks"),
            UIKeyCommand(action: #selector(addCurrentTabToBookmarks), input: "d", modifierFlags: .command, discoverabilityTitle: "Add Bookmark"),

            // Tools
            // TODO: String KeyboardShortcuts.ShowDownloads
            UIKeyCommand(action: #selector(showDownloads), input: "j", modifierFlags: .command, discoverabilityTitle: "Show Downloads"),

            // Window
            UIKeyCommand(action: #selector(showTabTrayKeyCommand), input: "\\", modifierFlags: [.command, .shift]), // Safari on macOS
            UIKeyCommand(action: #selector(nextTabKeyCommand), input: "]", modifierFlags: [.command, .shift]),
            UIKeyCommand(action: #selector(previousTabKeyCommand), input: "[", modifierFlags: [.command, .shift]),
            UIKeyCommand(action: #selector(nextTabKeyCommand), input: "\t", modifierFlags: .control, discoverabilityTitle: .ShowNextTabTitle),
            UIKeyCommand(action: #selector(previousTabKeyCommand), input: "\t", modifierFlags: [.control, .shift],  discoverabilityTitle: .ShowPreviousTabTitle),
            UIKeyCommand(action: #selector(showTabTrayKeyCommand), input: "\t", modifierFlags: [.command, .alternate], discoverabilityTitle: .ShowTabTrayFromTabKeyCodeTitle),
            // TODO: Show tab # 1-9 - Command + 1-9
        ]

        let isEditingText = tabManager.selectedTab?.isEditing ?? false

        if urlBar.inOverlayMode {
            return commands + searchLocationCommands
        } else if !isEditingText {
            return commands + overridesTextEditing
        }
        return commands
    }
}
