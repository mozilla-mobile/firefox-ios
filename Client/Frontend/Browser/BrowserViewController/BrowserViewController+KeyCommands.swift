/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

extension BrowserViewController {

    @objc private func reloadTab() {
        if homePanelController == nil {
            tabManager.selectedTab?.reload()
        }
    }

    @objc private func goBack() {
        if tabManager.selectedTab?.canGoBack == true && homePanelController == nil {
            tabManager.selectedTab?.goBack()
        }
    }
    @objc private func goForward() {
        if tabManager.selectedTab?.canGoForward == true && homePanelController == nil {
            tabManager.selectedTab?.goForward()
        }
    }

    @objc private func findOnPage() {
        if homePanelController == nil {
            tab( (tabManager.selectedTab)!, didSelectFindInPageForSelection: "")
        }
    }

    @objc private func selectLocationBar() {
        scrollController.showToolbars(animated: true)
        urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
    }

    @objc private func newTab() {
        openBlankNewTab(isPrivate: false)
    }

    @objc private func newPrivateTab() {
        openBlankNewTab(isPrivate: true)
    }

    @objc private func closeTab() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }
        tabManager.removeTab(currentTab)
    }

    @objc private func nextTab() {
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

    @objc private func previousTab() {
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

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(BrowserViewController.reloadTab), discoverabilityTitle: Strings.ReloadPageTitle),
            UIKeyCommand(input: "[", modifierFlags: .command, action: #selector(BrowserViewController.goBack), discoverabilityTitle: Strings.BackTitle),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: .command, action: #selector(BrowserViewController.goBack), discoverabilityTitle: Strings.BackTitle),
            UIKeyCommand(input: "]", modifierFlags: .command, action: #selector(BrowserViewController.goForward), discoverabilityTitle: Strings.ForwardTitle),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: .command, action: #selector(BrowserViewController.goForward), discoverabilityTitle: Strings.ForwardTitle),

            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(BrowserViewController.findOnPage), discoverabilityTitle: Strings.FindTitle),
            UIKeyCommand(input: "l", modifierFlags: .command, action: #selector(BrowserViewController.selectLocationBar), discoverabilityTitle: Strings.SelectLocationBarTitle),
            UIKeyCommand(input: "t", modifierFlags: .command, action: #selector(BrowserViewController.newTab), discoverabilityTitle: Strings.NewTabTitle),
            UIKeyCommand(input: "p", modifierFlags: [.command, .shift], action: #selector(BrowserViewController.newPrivateTab), discoverabilityTitle: Strings.NewPrivateTabTitle),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(BrowserViewController.closeTab), discoverabilityTitle: Strings.CloseTabTitle),
            UIKeyCommand(input: "\t", modifierFlags: .control, action: #selector(BrowserViewController.nextTab), discoverabilityTitle: Strings.ShowNextTabTitle),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [.command, .shift], action: #selector(BrowserViewController.nextTab), discoverabilityTitle: Strings.ShowNextTabTitle),
            UIKeyCommand(input: "\t", modifierFlags: [.control, .shift], action: #selector(BrowserViewController.previousTab), discoverabilityTitle: Strings.ShowPreviousTabTitle),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [.command, .shift], action: #selector(BrowserViewController.previousTab), discoverabilityTitle: Strings.ShowPreviousTabTitle),
        ]
    }
}
