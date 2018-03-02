/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

// Naming functions: use the suffix 'KeyCommand' for an additional level of namespacing (bug 1415830)
extension BrowserViewController {

    @objc private func reloadTabKeyCommand() {
        if let tab = tabManager.selectedTab, homePanelController == nil {
            tab.reload()
        }
    }

    @objc private func goBackKeyCommand() {
        if let tab = tabManager.selectedTab, tab.canGoBack, homePanelController == nil {
            tab.goBack()
        }
    }

    @objc private func goForwardKeyCommand() {
        if let tab = tabManager.selectedTab, tab.canGoForward {
            tab.goForward()
        }
    }

    @objc private func findOnPageKeyCommand() {
        if let tab = tabManager.selectedTab, homePanelController == nil {
            self.tab(tab, didSelectFindInPageForSelection: "")
        }
    }

    @objc private func selectLocationBarKeyCommand() {
        scrollController.showToolbars(animated: true)
        urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
    }

    @objc private func newTabKeyCommand() {
        openBlankNewTab(focusLocationField: true, isPrivate: false)
    }

    @objc private func newPrivateTabKeyCommand() {
        openBlankNewTab(focusLocationField: true, isPrivate: true)
    }

    @objc private func closeTabKeyCommand() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }
        tabManager.removeTab(currentTab)
    }

    @objc private func nextTabKeyCommand() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.index(of: currentTab), index + 1 < tabs.count {
            tabManager.selectTab(tabs[index + 1])
        } else if let firstTab = tabs.first {
            tabManager.selectTab(firstTab)
        }
    }

    @objc private func previousTabKeyCommand() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.index(of: currentTab), index - 1 < tabs.count && index != 0 {
            tabManager.selectTab(tabs[index - 1])
        } else if let lastTab = tabs.last {
            tabManager.selectTab(lastTab)
        }
    }

    @objc private func gotoTabTray() {
        showTabTray()
    }

    @objc private func awesomeBarItemKeyCommand(sender: UIKeyCommand) {
        guard let searchController = self.searchController else {
            return
        }

        searchController.becomeFirstResponder()
        searchController.handleKeyCommands(sender: sender)
    }


    override var keyCommands: [UIKeyCommand]? {
        let overlayCommands = [
            UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(awesomeBarItemKeyCommand(sender:))),
        ]
        let overidesTextEditing = [
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [.command, .shift], action: #selector(nextTabKeyCommand)),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [.command, .shift], action: #selector(previousTabKeyCommand)),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: .command, action: #selector(goBackKeyCommand)),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: .command, action: #selector(goForwardKeyCommand)),
        ]
        let tabNavigation = [
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(reloadTabKeyCommand), discoverabilityTitle: Strings.ReloadPageTitle),
            UIKeyCommand(input: "[", modifierFlags: .command, action: #selector(goBackKeyCommand), discoverabilityTitle: Strings.BackTitle),
            UIKeyCommand(input: "]", modifierFlags: .command, action: #selector(goForwardKeyCommand), discoverabilityTitle: Strings.ForwardTitle),

            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(findOnPageKeyCommand), discoverabilityTitle: Strings.FindTitle),
            UIKeyCommand(input: "l", modifierFlags: .command, action: #selector(selectLocationBarKeyCommand), discoverabilityTitle: Strings.SelectLocationBarTitle),
            UIKeyCommand(input: "t", modifierFlags: .command, action: #selector(newTabKeyCommand), discoverabilityTitle: Strings.NewTabTitle),
            UIKeyCommand(input: "p", modifierFlags: [.command, .shift], action: #selector(newPrivateTabKeyCommand), discoverabilityTitle: Strings.NewPrivateTabTitle),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(closeTabKeyCommand), discoverabilityTitle: Strings.CloseTabTitle),
            UIKeyCommand(input: "\t", modifierFlags: .control, action: #selector(nextTabKeyCommand), discoverabilityTitle: Strings.ShowNextTabTitle),
            UIKeyCommand(input: "\t", modifierFlags: [.control, .shift], action: #selector(previousTabKeyCommand), discoverabilityTitle: Strings.ShowPreviousTabTitle),

            // Switch tab to match Safari on iOS.
            UIKeyCommand(input: "]", modifierFlags: [.command, .shift], action: #selector(nextTabKeyCommand)),
            UIKeyCommand(input: "[", modifierFlags: [.command, .shift], action: #selector(previousTabKeyCommand)),

            UIKeyCommand(input: "\\", modifierFlags: [.command, .shift], action: #selector(gotoTabTray)), // Safari on macOS
            UIKeyCommand(input: "\t", modifierFlags: [.command, .alternate], action: #selector(gotoTabTray), discoverabilityTitle: Strings.ShowTabTrayFromTabKeyCodeTitle)
        ]

        let isEditingText = tabManager.selectedTab?.isEditing ?? false

        if urlBar.inOverlayMode {
            return tabNavigation + overlayCommands
        } else if isEditingText {
            return tabNavigation
        } else {
            return tabNavigation + overidesTextEditing
        }
    }
}
