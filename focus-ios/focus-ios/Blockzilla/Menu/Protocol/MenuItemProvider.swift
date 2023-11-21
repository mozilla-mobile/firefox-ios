/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import AppShortcuts

protocol MenuItemProvider {
    var shortcutManager: ShortcutsManager { get }

    func openInFireFoxItem(for url: URL) -> MenuAction?
    func openInChromeItem(for url: URL) -> MenuAction?

    var findInPageItem: MenuAction { get }
    var requestDesktopItem: MenuAction { get }
    var requestMobileItem: MenuAction { get }
    var settingsItem: MenuAction { get }
    var helpItem: MenuAction { get }

    func getShortcutsItem(for url: URL) -> MenuAction?
    func addToShortcutsItem(for url: URL) -> MenuAction
    func removeFromShortcutsItem(for url: URL) -> MenuAction

    func openInDefaultBrowserItem(for url: URL) -> MenuAction
    func copyItem(url: URL) -> MenuAction
    func sharePageItem(for utils: OpenUtils, sender: UIView) -> MenuAction
}

extension MenuItemProvider where Self: MenuActionable {
    func openInFireFoxItem(for url: URL) -> MenuAction? {
        canOpenInFirefox

        ? MenuAction(title: UIConstants.strings.shareOpenInFirefox, image: "open_in_firefox_icon") { [unowned self] in
            self.openInFirefox(url: url)
        }
        : nil
    }

    func openInChromeItem(for url: URL) -> MenuAction? {
        canOpenInChrome ?
        MenuAction(title: UIConstants.strings.shareOpenInChrome, image: "open_in_chrome_icon") { [unowned self] in
            self.openInChrome(url: url)
        }
        : nil
    }

    var findInPageItem: MenuAction {
        MenuAction(title: UIConstants.strings.shareMenuFindInPage, image: "icon_searchfor") { [unowned self] in
            self.findInPage()
        }
    }

    var requestDesktopItem: MenuAction {
        MenuAction(title: UIConstants.strings.shareMenuRequestDesktop, image: "request_desktop_site_activity") { [unowned self] in
            self.requestDesktopBrowsing()
        }
    }

    var requestMobileItem: MenuAction {
        MenuAction(title: UIConstants.strings.shareMenuRequestMobile, image: "request_mobile_site_activity") { [unowned self] in
            self.requestMobileBrowsing()
        }
    }

    var settingsItem: MenuAction {
        MenuAction(title: UIConstants.strings.settingsTitle, image: "icon_settings") { [unowned self] in
            self.showSettings(shouldScrollToSiri: false)
        }
    }

    var helpItem: MenuAction {
        MenuAction(title: UIConstants.strings.aboutRowHelp, image: "icon_help") { [unowned self] in
            self.showHelp()
        }
    }

    func getShortcutsItem(for url: URL) -> MenuAction? {
        if shortcutManager.isSaved(url: url) {
            return removeFromShortcutsItem(for: url)
        } else if shortcutManager.hasSpace {
            return addToShortcutsItem(for: url)
        } else {
            return nil
        }
    }

    func addToShortcutsItem(for url: URL) -> MenuAction {
        MenuAction(title: UIConstants.strings.shareMenuAddToShortcuts, image: "icon_shortcuts_add") { [unowned self] in
            self.addToShortcuts(url: url)
        }
    }

    func removeFromShortcutsItem(for url: URL) -> MenuAction {
        MenuAction(title: UIConstants.strings.shareMenuRemoveFromShortcuts, image: "icon_shortcuts_remove") { [unowned self] in
            self.removeShortcut(url: url)
        }
    }

    func openInDefaultBrowserItem(for url: URL) -> MenuAction {
        MenuAction(title: UIConstants.strings.shareOpenInDefaultBrowser, image: "icon_favicon") { [unowned self] in
            self.openInDefaultBrowser(url: url)
        }
    }

    func sharePageItem(for utils: OpenUtils, sender: UIView) -> MenuAction {
        MenuAction(title: UIConstants.strings.sharePage, image: "icon_openwith_active") { [unowned self] in
            self.showSharePage(for: utils, sender: sender)
        }
    }

    func copyItem(url: URL) -> MenuAction {
        MenuAction(title: UIConstants.strings.copyAddress, image: "icon_link") { [unowned self] in
            self.showCopy(url: url)
        }
    }
}
