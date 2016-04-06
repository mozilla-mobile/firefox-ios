/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TabAction: Actionable {
    func performAction(action: Action) {
        switch(action) {
        case .OpenNewTab(let isPrivate, let url, let tabManager, let tabTrayController, let themer):
            if let tabTrayController = tabTrayController where tabTrayController.privateMode != isPrivate {
                switchToPrivacyMode(isPrivate, tabTrayController: tabTrayController, themer: themer)
            }
            openNewTab(isPrivate, url: url, tabManager: tabManager)
        case .OpenExistingTabOrOpenNew(let isPrivate, let url, let tabManager, let currentViewController, let tabTrayController, let themer):
            if let tabTrayController = tabTrayController where tabTrayController.privateMode != isPrivate {
                switchToPrivacyMode(isPrivate, tabTrayController: tabTrayController, themer: themer)
            }
            switchToTabForURLOrOpen(isPrivate, url: url, tabManager: tabManager, currentViewController: currentViewController)
        case .OpenNewTabAndFocus(let isPrivate, let url, let tabManager, let urlBar, let currentViewController):
            openNewTabAndFocus(isPrivate, url: url, tabManager: tabManager, currentViewController: currentViewController, urlBar: urlBar)
        }
    }

    private func switchToPrivacyMode(isPrivate: Bool, tabTrayController: TabTrayController, themer: Themeable?) {
        if #available(iOS 9, *) {
            if let themer = themer {
                themer.applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)
            }
            tabTrayController.changePrivacyMode(isPrivate)
        }
    }

    private func openNewTab(isPrivate: Bool = false, url: NSURL? = nil, tabManager: TabManager, inBackground: Bool = false) {
        let urlRequest: NSURLRequest?
        if let url = url {
            urlRequest = NSURLRequest(URL: url)
        } else {
            urlRequest = nil
        }
        if inBackground {
            tabManager.addTab(urlRequest, isPrivate: isPrivate)
        } else {
            tabManager.addTabAndSelect(urlRequest, isPrivate: isPrivate)
        }
    }

    private func switchToTabForURLOrOpen(isPrivate: Bool = false, url: NSURL?, tabManager: TabManager, currentViewController: UIViewController) {
        let tab: Tab?
        if let url = url {
            tab = tabManager.getTabForURL(url)
        } else {
            tab = nil
        }
        popToTab(tab, currentViewController: currentViewController)
        if let tab = tab {
            tabManager.selectTab(tab)
        } else {
            openNewTab(isPrivate, url: url, tabManager: tabManager)
        }
    }

    private func openNewTabAndFocus(isPrivate: Bool, url: NSURL?, tabManager: TabManager, currentViewController: UIViewController, urlBar: URLBarView) {
        switchToTabForURLOrOpen(isPrivate, url: url, tabManager: tabManager, currentViewController: currentViewController)
        urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
    }

    private func popToTab(forTab: Tab? = nil, currentViewController: UIViewController) {
        guard let topViewController = currentViewController.navigationController?.topViewController else {
            return
        }
        if let presentedViewController = topViewController.presentedViewController {
            presentedViewController.dismissViewControllerAnimated(false, completion: nil)
        }
        // if a tab already exists and the top VC is not the BVC then pop the top VC, otherwise don't.
        if topViewController != currentViewController {
            currentViewController.navigationController?.popViewControllerAnimated(true)
        }
    }
}
