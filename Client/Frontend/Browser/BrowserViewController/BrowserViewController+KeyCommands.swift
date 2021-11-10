/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

// Naming functions: use the suffix 'KeyCommand' for an additional level of namespacing (bug 1415830)
extension BrowserViewController {

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
        tabManager.removeTabAndUpdateSelectedIndex(currentTab)
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
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(moveURLCompletionKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(moveURLCompletionKeyCommand(sender:))),
        ]
        let overidesTextEditing = [
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [.command, .shift], action: #selector(nextTabKeyCommand)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [.command, .shift], action: #selector(previousTabKeyCommand)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: .command, action: #selector(goBackKeyCommand)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: .command, action: #selector(goForwardKeyCommand)),
        ]
        let tabNavigation = [
            UIKeyCommand(action: #selector(reloadTabKeyCommand), input: "r", modifierFlags: .command, discoverabilityTitle: .ReloadPageTitle),
            UIKeyCommand(action: #selector(goBackKeyCommand), input: "[", modifierFlags: .command, discoverabilityTitle: .BackTitle),
            UIKeyCommand(action: #selector(goForwardKeyCommand), input: "]", modifierFlags: .command, discoverabilityTitle: .ForwardTitle),
            UIKeyCommand(action: #selector(findInPageKeyCommand), input: "f", modifierFlags: .command, discoverabilityTitle: .FindTitle),
            UIKeyCommand(action: #selector(selectLocationBarKeyCommand), input: "l", modifierFlags: .command, discoverabilityTitle: .SelectLocationBarTitle),
            UIKeyCommand(action: #selector(newTabKeyCommand), input: "t", modifierFlags: .command, discoverabilityTitle: .NewTabTitle),
            UIKeyCommand(action: #selector(newPrivateTabKeyCommand), input: "p", modifierFlags: [.command, .shift], discoverabilityTitle: .NewPrivateTabTitle),
            UIKeyCommand(action: #selector(closeTabKeyCommand), input: "w", modifierFlags: .command, discoverabilityTitle: .CloseTabTitle),
            UIKeyCommand(action: #selector(nextTabKeyCommand), input: "\t", modifierFlags: .control, discoverabilityTitle: .ShowNextTabTitle),
            UIKeyCommand(action: #selector(previousTabKeyCommand), input: "\t", modifierFlags: [.control, .shift],  discoverabilityTitle: .ShowPreviousTabTitle),

            // Switch tab to match Safari on iOS.
            UIKeyCommand(input: "]", modifierFlags: [.command, .shift], action: #selector(nextTabKeyCommand)),
            UIKeyCommand(input: "[", modifierFlags: [.command, .shift], action: #selector(previousTabKeyCommand)),

            UIKeyCommand(input: "\\", modifierFlags: [.command, .shift], action: #selector(showTabTrayKeyCommand)), // Safari on macOS
            UIKeyCommand(action: #selector(showTabTrayKeyCommand), input: "\t", modifierFlags: [.command, .alternate], discoverabilityTitle: .ShowTabTrayFromTabKeyCodeTitle)

        ]

        let isEditingText = tabManager.selectedTab?.isEditing ?? false

        if urlBar.inOverlayMode {
            return tabNavigation + searchLocationCommands
        } else if !isEditingText {
            return tabNavigation + overidesTextEditing
        }
        return tabNavigation
    }
}
