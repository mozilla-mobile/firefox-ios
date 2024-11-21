// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

class MenuBuilderHelper {
    struct MenuIdentifiers {
        static let history = UIMenu.Identifier("com.mozilla.firefox.menus.history")
        static let bookmarks = UIMenu.Identifier("com.mozilla.firefox.menus.bookmarks")
        static let tools = UIMenu.Identifier("com.mozilla.firefox.menus.tools")
    }

    func mainMenu(for builder: UIMenuBuilder) {
        let newPrivateTab = UICommandAlternate(
            title: .KeyboardShortcuts.NewPrivateTab,
            action: #selector(BrowserViewController.newPrivateTabKeyCommand),
            modifierFlags: [.shift]
        )

        let applicationMenu = UIMenu(
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: .AppSettingsTitle,
                    action: #selector(BrowserViewController.openSettingsKeyCommand),
                    input: ",",
                    modifierFlags: .command,
                    discoverabilityTitle: .AppSettingsTitle
                )
            ]
        )

        let fileMenu = UIMenu(
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: .KeyboardShortcuts.NewTab,
                    action: #selector(BrowserViewController.newTabKeyCommand),
                    input: "t",
                    modifierFlags: .command,
                    alternates: [newPrivateTab],
                    discoverabilityTitle: .KeyboardShortcuts.NewTab
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.NewPrivateTab,
                    action: #selector(BrowserViewController.newPrivateTabKeyCommand),
                    input: "p",
                    modifierFlags: [.command, .shift],
                    discoverabilityTitle: .KeyboardShortcuts.NewPrivateTab
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.SelectLocationBar,
                    action: #selector(BrowserViewController.selectLocationBarKeyCommand),
                    input: "l",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.SelectLocationBar
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.CloseCurrentTab,
                    action: #selector(BrowserViewController.closeTabKeyCommand),
                    input: "w",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.CloseCurrentTab
                ),
            ]
        )
        fileMenu.children.forEach {
            ($0 as? UIKeyCommand)?.wantsPriorityOverSystemBehavior = true
        }

        let findMenu = UIMenu(
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: .KeyboardShortcuts.Find,
                    action: #selector(BrowserViewController.findInPageKeyCommand),
                    input: "f",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.Find
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.FindAgain,
                    action: #selector(BrowserViewController.findInPageAgainKeyCommand),
                    input: "g",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.FindAgain
                ),
            ]
        )
        findMenu.children.forEach {
            ($0 as? UIKeyCommand)?.wantsPriorityOverSystemBehavior = true
        }

        var viewMenuChildren: [UIMenuElement] = [
            UIKeyCommand(
                title: .KeyboardShortcuts.ZoomIn,
                action: #selector(BrowserViewController.zoomIn),
                input: "+",
                modifierFlags: .command,
                discoverabilityTitle: .KeyboardShortcuts.ZoomIn
            ),
            UIKeyCommand(
                title: .KeyboardShortcuts.ZoomOut,
                action: #selector(BrowserViewController.zoomOut),
                input: "-",
                modifierFlags: .command,
                discoverabilityTitle: .KeyboardShortcuts.ZoomOut
            ),
            UIKeyCommand(
                title: .KeyboardShortcuts.ActualSize,
                action: #selector(BrowserViewController.resetZoom),
                input: "0",
                modifierFlags: .command,
                discoverabilityTitle: .KeyboardShortcuts.ActualSize
            ),
            UIKeyCommand(
                title: .KeyboardShortcuts.ReloadPage,
                action: #selector(BrowserViewController.reloadTabKeyCommand),
                input: "r",
                modifierFlags: .command,
                discoverabilityTitle: .KeyboardShortcuts.ReloadPage
            )
        ]

        // UIKeyCommand.f5 is only available since iOS 13.4 - Shortcut will only work from this version
        viewMenuChildren.append(
            UIKeyCommand(
                title: .KeyboardShortcuts.ReloadWithoutCache,
                action: #selector(BrowserViewController.reloadTabIgnoringCacheKeyCommand),
                input: UIKeyCommand.f5,
                modifierFlags: [.control],
                discoverabilityTitle: .KeyboardShortcuts.ReloadWithoutCache
            )
        )

        let viewMenu = UIMenu(options: .displayInline, children: viewMenuChildren)
        viewMenu.children.forEach {
            ($0 as? UIKeyCommand)?.wantsPriorityOverSystemBehavior = true
        }

        let historyMenu = UIMenu(
            title: .KeyboardShortcuts.Sections.History,
            identifier: MenuIdentifiers.history,
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: .KeyboardShortcuts.ShowHistory,
                    action: #selector(BrowserViewController.showHistoryKeyCommand),
                    input: "y",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.ShowHistory
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.Back,
                    action: #selector(BrowserViewController.goBackKeyCommand),
                    input: "[",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.Back
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.Forward,
                    action: #selector(BrowserViewController.goForwardKeyCommand),
                    input: "]",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.Forward
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.ClearRecentHistory,
                    action: #selector(BrowserViewController.openClearHistoryPanelKeyCommand),
                    input: "\u{8}",
                    modifierFlags: [.command, .shift],
                    discoverabilityTitle: .KeyboardShortcuts.ClearRecentHistory
                )
            ]
        )

        let bookmarksMenu = UIMenu(
            title: .KeyboardShortcuts.Sections.Bookmarks,
            identifier: MenuIdentifiers.bookmarks,
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: .KeyboardShortcuts.ShowBookmarks,
                    action: #selector(BrowserViewController.showBookmarksKeyCommand),
                    input: "o",
                    modifierFlags: [.command, .shift],
                    discoverabilityTitle: .KeyboardShortcuts.ShowBookmarks
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.AddBookmark,
                    action: #selector(BrowserViewController.addBookmarkKeyCommand),
                    input: "d",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.AddBookmark
                )
            ]
        )

        let toolsMenu = UIMenu(
            title: .KeyboardShortcuts.Sections.Tools,
            identifier: MenuIdentifiers.tools,
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: .KeyboardShortcuts.ShowDownloads,
                    action: #selector(BrowserViewController.showDownloadsKeyCommand),
                    input: "j",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.ShowDownloads
                )
            ]
        )

        let windowMenu = UIMenu(
            title: .KeyboardShortcuts.Sections.Window,
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: .KeyboardShortcuts.ShowNextTab,
                    action: #selector(BrowserViewController.nextTabKeyCommand),
                    input: "\t",
                    modifierFlags: [.control],
                    discoverabilityTitle: .KeyboardShortcuts.ShowNextTab
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.ShowPreviousTab,
                    action: #selector(BrowserViewController.previousTabKeyCommand),
                    input: "\t",
                    modifierFlags: [.control, .shift],
                    discoverabilityTitle: .KeyboardShortcuts.ShowPreviousTab
                ),
                UIKeyCommand(
                    title: .KeyboardShortcuts.ShowTabTray,
                    action: #selector(BrowserViewController.showTabTrayKeyCommand),
                    input: "\t",
                    modifierFlags: [.command, .alternate],
                    discoverabilityTitle: .KeyboardShortcuts.ShowTabTray
                ),
                UIKeyCommand(
                    action: #selector(BrowserViewController.selectFirstTab),
                    input: "1",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.ShowFirstTab
                ),
                UIKeyCommand(
                    action: #selector(BrowserViewController.selectLastTab),
                    input: "9",
                    modifierFlags: .command,
                    discoverabilityTitle: .KeyboardShortcuts.ShowLastTab
                ),
            ]
        )

        windowMenu.children.forEach {
            ($0 as? UIKeyCommand)?.wantsPriorityOverSystemBehavior = true
        }

        builder.insertChild(applicationMenu, atStartOfMenu: .application)
        builder.insertChild(fileMenu, atStartOfMenu: .file)
        builder.replace(menu: .find, with: findMenu)
        builder.remove(menu: .font)
        builder.insertChild(viewMenu, atStartOfMenu: .view)
        builder.insertSibling(historyMenu, afterMenu: .view)
        builder.insertSibling(bookmarksMenu, afterMenu: MenuIdentifiers.history)
        builder.insertSibling(toolsMenu, afterMenu: MenuIdentifiers.bookmarks)
        builder.insertChild(windowMenu, atStartOfMenu: .window)
    }
}
