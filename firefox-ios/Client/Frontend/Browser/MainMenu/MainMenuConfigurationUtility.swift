// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Shared

struct MainMenuConfigurationUtility: Equatable {
    private struct Icons {
        static let newTab = StandardImageIdentifiers.Large.plus
        static let newPrivateTab = StandardImageIdentifiers.Large.privateModeCircleFill
        static let deviceDesktop = StandardImageIdentifiers.Large.deviceDesktop
        static let findInPage = StandardImageIdentifiers.Large.search
        static let tools = StandardImageIdentifiers.Large.tool
        static let save = StandardImageIdentifiers.Large.save
        static let bookmarks = StandardImageIdentifiers.Large.bookmarkTrayFill
        static let history = StandardImageIdentifiers.Large.history
        static let downloads = StandardImageIdentifiers.Large.download
        static let passwords = StandardImageIdentifiers.Large.login
        static let getHelp = StandardImageIdentifiers.Large.helpCircle
        static let settings = StandardImageIdentifiers.Large.settings
        static let whatsNew = StandardImageIdentifiers.Large.whatsNew
        static let zoom = StandardImageIdentifiers.Large.pageZoom
        static let readerViewOn = StandardImageIdentifiers.Large.readerView
        static let nightModeOn = StandardImageIdentifiers.Large.nightMode
        static let print = StandardImageIdentifiers.Large.print
        static let share = StandardImageIdentifiers.Large.share
        static let addToShortcuts = StandardImageIdentifiers.Large.pin
        static let removeFromShortcuts = StandardImageIdentifiers.Large.pinSlash
        static let saveToReadingList = StandardImageIdentifiers.Large.readingListAdd
        static let removeFromReadingList = StandardImageIdentifiers.Large.readingListSlashFill
        static let bookmarkThisPage = StandardImageIdentifiers.Large.bookmark
        static let reportBrokenSite = StandardImageIdentifiers.Large.lightbulb
        static let customizeHomepage = StandardImageIdentifiers.Large.gridAdd
        static let saveAsPDF = StandardImageIdentifiers.Large.folder

        // These will be used in the future, but not now.
        // adding them just for completion's sake
        //        static let addToHomescreen = StandardImageIdentifiers.Large.addToHomescreen
    }

    public func generateMenuElements(
        with tabInfo: MainMenuTabInfo,
        for viewType: MainMenuDetailsViewType?,
        and uuid: WindowUUID
    ) -> [MenuSection] {
        switch viewType {
        case .tools: return getToolsSubmenu(with: uuid)
        case .save: return getSaveSubmenu(with: uuid, and: tabInfo)
        default: return getMainMenuElements(with: uuid, and: tabInfo)
        }
    }

    // MARK: - Main Menu
    private func getMainMenuElements(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> [MenuSection] {
        // Always include these sections
        var menuSections: [MenuSection] = [
            getNewTabSection(with: uuid),
            getLibrariesSection(with: uuid),
            getOtherToolsSection(
                with: uuid,
                isHomepage: tabInfo.isHomepage
            )
        ]

        // Conditionally add tools section if this is a website
        if !tabInfo.isHomepage {
            menuSections.insert(
                getToolsSection(with: uuid, and: tabInfo),
                at: 1
            )
        }

        return menuSections
    }

    // MARK: - New Tabs Section
    private func getNewTabSection(with uuid: WindowUUID) -> MenuSection {
        return MenuSection(options: [
            MenuElement(
                title: .MainMenu.TabsSection.NewTab,
                iconName: Icons.newTab,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.TabsSection.AccessibilityLabels.NewTab,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.newTab,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.newTab)
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.TabsSection.NewPrivateTab,
                iconName: Icons.newPrivateTab,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.TabsSection.AccessibilityLabels.NewPrivateTab,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.newPrivateTab,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.newPrivateTab)
                        )
                    )
                }
            )
        ])
    }

    // MARK: - Tools Section
    private func getToolsSection(
        with uuid: WindowUUID,
        and configuration: MainMenuTabInfo
    ) -> MenuSection {
        return MenuSection(
            options: [
                MenuElement(
                    title: getUserAgentTitle(
                        defaultIsDesktop: configuration.isDefaultUserAgentDesktop,
                        tabHasChangedUserAgent: configuration.hasChangedUserAgent
                    ),
                    iconName: Icons.deviceDesktop,
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.SwitchToDesktopSite,
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.switchToDesktopSite,
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.toggleUserAgent
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.ToolsSection.FindInPage,
                    iconName: Icons.findInPage,
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.FindInPage,
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.findInPage,
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(.findInPage)
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.ToolsSection.Tools,
                    iconName: Icons.tools,
                    isEnabled: true,
                    isActive: false,
                    hasSubmenu: true,
                    a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.Tools,
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.tools,
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.showDetailsView,
                                changeMenuViewTo: .tools
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.ToolsSection.Save,
                    iconName: Icons.save,
                    isEnabled: true,
                    isActive: false,
                    hasSubmenu: true,
                    a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.Save,
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.save,
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.showDetailsView,
                                changeMenuViewTo: .save
                            )
                        )
                    }
                )
            ]
        )
    }

    private func getUserAgentTitle(
        defaultIsDesktop: Bool,
        tabHasChangedUserAgent: Bool
    ) -> String {
        typealias Menu = String.MainMenu.ToolsSection

        // Our default User Agent gets set depending on the architecture we're
        // running on. For example, if we're building on an Intel Mac, we get
        // desktop User Agent by default. Thus, to determine which string to use,
        // we need to know:
        //   1) which architecture we've started from and
        //   2) whether or not we've requested to change the user agent in the tab
        // Using this information, we're able to present the correct string for
        // the "Request Mobile/Desktop Site" menu option
        if defaultIsDesktop {
            return tabHasChangedUserAgent ? Menu.SwitchToDesktopSite : Menu.SwitchToMobileSite
        } else {
            return tabHasChangedUserAgent ? Menu.SwitchToMobileSite : Menu.SwitchToDesktopSite
        }
    }

    // MARK: - Tools Submenu
    private func getToolsSubmenu(with uuid: WindowUUID) -> [MenuSection] {
        return [
            MenuSection(
                options: [
                    MenuElement(
                        title: .MainMenu.Submenus.Tools.Zoom,
                        iconName: Icons.zoom,
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.Zoom,
                        a11yHint: "",
                        a11yId: AccessibilityIdentifiers.MainMenu.zoom,
                        action: {
                            store.dispatch(
                                MainMenuAction(
                                    windowUUID: uuid,
                                    actionType: MainMenuActionType.closeMenu
                                )
                            )
                        }
                    ),
                    MenuElement(
                        title: .MainMenu.Submenus.Tools.ReaderViewOn,
                        iconName: Icons.readerViewOn,
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.ReaderViewOn,
                        a11yHint: "",
                        a11yId: AccessibilityIdentifiers.MainMenu.readerViewOn,
                        action: {
                            store.dispatch(
                                MainMenuAction(
                                    windowUUID: uuid,
                                    actionType: MainMenuActionType.closeMenu
                                )
                            )
                        }
                    ),
                    MenuElement(
                        title: .MainMenu.Submenus.Tools.NightModeOn,
                        iconName: Icons.nightModeOn,
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.NightModeOn,
                        a11yHint: "",
                        a11yId: AccessibilityIdentifiers.MainMenu.nightModeOn,
                        action: {
                            store.dispatch(
                                MainMenuAction(
                                    windowUUID: uuid,
                                    actionType: MainMenuActionType.closeMenu
                                )
                            )
                        }
                    ),
                    MenuElement(
                        title: .MainMenu.Submenus.Tools.ReportBrokenSite,
                        iconName: Icons.reportBrokenSite,
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.ReportBrokenSite,
                        a11yHint: "",
                        a11yId: AccessibilityIdentifiers.MainMenu.reportBrokenSite,
                        action: {
                            store.dispatch(
                                MainMenuAction(
                                    windowUUID: uuid,
                                    actionType: MainMenuActionType.closeMenu
                                )
                            )
                        }
                    )
                ]
            ),
            MenuSection(
                options: [
                    MenuElement(
                        title: .MainMenu.Submenus.Tools.Print,
                        iconName: Icons.print,
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.Print,
                        a11yHint: "",
                        a11yId: AccessibilityIdentifiers.MainMenu.print,
                        action: {
                            store.dispatch(
                                MainMenuAction(
                                    windowUUID: uuid,
                                    actionType: MainMenuActionType.closeMenu
                                )
                            )
                        }
                    ),
                    MenuElement(
                        title: .MainMenu.Submenus.Tools.Share,
                        iconName: Icons.share,
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.Share,
                        a11yHint: "",
                        a11yId: AccessibilityIdentifiers.MainMenu.share,
                        action: {
                            store.dispatch(
                                MainMenuAction(
                                    windowUUID: uuid,
                                    actionType: MainMenuActionType.closeMenu
                                )
                            )
                        }
                    )
                ]
            )
        ]
    }

    // MARK: - Save Submenu
    private func getSaveSubmenu(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> [MenuSection] {
        return [MenuSection(
            options: [
                configureBookmarkItem(with: uuid, and: tabInfo),
                configureShortcutsItem(with: uuid, and: tabInfo),
                configureReadingListItem(with: uuid, and: tabInfo)
            ]
        )]
    }

    private func configureBookmarkItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias SaveMenu = String.MainMenu.Submenus.Save
        typealias A11y = SaveMenu.AccessibilityLabels

        let title = tabInfo.isBookmarked ? SaveMenu.EditBookmark : SaveMenu.BookmarkThisPage
        let a11yLabel = tabInfo.isBookmarked ? A11y.EditBookmark : A11y.BookmarkThisPage
        let actionType: MainMenuDetailsActionType = tabInfo.isBookmarked ? .editBookmark : .addToBookmarks

        return MenuElement(
            title: title,
            iconName: Icons.bookmarkThisPage,
            isEnabled: true,
            isActive: tabInfo.isBookmarked,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.bookmarkThisPage,
            action: {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID
                    )
                )
            }
        )
    }

    private func configureShortcutsItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias SaveMenu = String.MainMenu.Submenus.Save
        typealias A11y = SaveMenu.AccessibilityLabels

        let title = tabInfo.isPinned ? SaveMenu.RemoveFromShortcuts : SaveMenu.AddToShortcuts
        let icon = tabInfo.isPinned ? Icons.removeFromShortcuts : Icons.addToShortcuts
        let a11yLabel = tabInfo.isPinned ? A11y.RemoveFromShortcuts : A11y.AddToShortcuts
        let actionType: MainMenuDetailsActionType = tabInfo.isPinned ? .removeFromShortcuts : .addToShortcuts

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: tabInfo.isPinned,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.addToShortcuts,
            action: {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID
                    )
                )
            }
        )
    }

    private func configureReadingListItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias SaveMenu = String.MainMenu.Submenus.Save
        typealias A11y = SaveMenu.AccessibilityLabels

        let title = tabInfo.isInReadingList ? SaveMenu.RemoveFromReadingList : SaveMenu.SaveToReadingList
        let icon = tabInfo.isInReadingList ? Icons.removeFromReadingList : Icons.saveToReadingList
        let a11yLabel = tabInfo.isInReadingList ? A11y.RemoveFromReadingList : A11y.SaveToReadingList
        let actionType: MainMenuDetailsActionType = tabInfo.isInReadingList ? .removeFromReadingList : .addToReadingList

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: tabInfo.readerModeIsAvailable,
            isActive: tabInfo.isInReadingList,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.saveToReadingList,
            action: {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID
                    )
                )
            }
        )
    }

    // MARK: - Libraries Section
    private func getLibrariesSection(with uuid: WindowUUID) -> MenuSection {
        return MenuSection(options: [
            MenuElement(
                title: .MainMenu.PanelLinkSection.Bookmarks,
                iconName: Icons.bookmarks,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.PanelLinkSection.AccessibilityLabels.Bookmarks,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.bookmarks,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.bookmarks)
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.PanelLinkSection.History,
                iconName: Icons.history,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.PanelLinkSection.AccessibilityLabels.History,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.history,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.history)
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.PanelLinkSection.Downloads,
                iconName: Icons.downloads,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.PanelLinkSection.AccessibilityLabels.Downloads,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.downloads,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.downloads)
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.PanelLinkSection.Passwords,
                iconName: Icons.passwords,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.PanelLinkSection.AccessibilityLabels.Passwords,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.passwords,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.passwords)
                        )
                    )
                }
            )
        ])
    }

    // MARK: - Other Tools Section
    private func getOtherToolsSection(
        with uuid: WindowUUID,
        isHomepage: Bool
    ) -> MenuSection {
        let homepageOptions = [
            MenuElement(
                title: .MainMenu.OtherToolsSection.CustomizeHomepage,
                iconName: Icons.customizeHomepage,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.OtherToolsSection.AccessibilityLabels.CustomizeHomepage,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.customizeHomepage,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.customizeHomepage)
                        )
                    )
                }
            ),
            MenuElement(
                title: String(
                    format: .MainMenu.OtherToolsSection.WhatsNew,
                    AppName.shortName.rawValue
                ),
                iconName: Icons.whatsNew,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.OtherToolsSection.AccessibilityLabels.WhatsNew,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.whatsNew,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(
                                .goToURL,
                                urlToVisit: SupportUtils.URLForWhatsNew
                            )
                        )
                    )
                }
            )
        ]

        let standardOptions = [
            MenuElement(
                title: .MainMenu.OtherToolsSection.GetHelp,
                iconName: Icons.getHelp,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.OtherToolsSection.AccessibilityLabels.GetHelp,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.getHelp,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(
                                .goToURL,
                                urlToVisit: SupportUtils.URLForGetHelp
                            )
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.OtherToolsSection.Settings,
                iconName: Icons.settings,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.OtherToolsSection.AccessibilityLabels.Settings,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.settings,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.settings)
                        )
                    )
                }
            )
        ]

        return MenuSection(options: isHomepage ? homepageOptions + standardOptions : standardOptions)
    }
}
