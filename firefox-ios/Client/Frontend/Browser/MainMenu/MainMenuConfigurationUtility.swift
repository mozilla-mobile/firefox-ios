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
        static let deviceMobile = StandardImageIdentifiers.Large.deviceMobile
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
        static let zoomOff = StandardImageIdentifiers.Large.pageZoom
        static let zoomOn = StandardImageIdentifiers.Large.pageZoomFill
        static let readerViewOn = StandardImageIdentifiers.Large.readerView
        static let readerViewOff = StandardImageIdentifiers.Large.readerViewFill
        static let nightModeOff = StandardImageIdentifiers.Large.nightMode
        static let nightModeOn = StandardImageIdentifiers.Large.nightModeFill
        static let print = StandardImageIdentifiers.Large.print
        static let share = StandardImageIdentifiers.Large.share
        static let addToShortcuts = StandardImageIdentifiers.Large.pin
        static let removeFromShortcuts = StandardImageIdentifiers.Large.pinSlash
        static let saveToReadingList = StandardImageIdentifiers.Large.readingListAdd
        static let removeFromReadingList = StandardImageIdentifiers.Large.readingListSlashFill
        static let bookmarkThisPage = StandardImageIdentifiers.Large.bookmark
        static let editThisBookmark = StandardImageIdentifiers.Large.bookmarkFill
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
        and uuid: WindowUUID,
        readerState: ReaderModeState? = nil
    ) -> [MenuSection] {
        switch viewType {
        case .tools:
            return getToolsSubmenu(with: uuid, tabInfo: tabInfo, and: readerState)

        case .save:
            return getSaveSubmenu(with: uuid, and: tabInfo)

        default:
            return getMainMenuElements(with: uuid, and: tabInfo)
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
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
                configureUserAgentItem(with: uuid, tabInfo: configuration),
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
                                actionType: MainMenuActionType.tapNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(.findInPage)
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.ToolsSection.Tools,
                    description: getToolsSubmenuDescription(with: configuration),
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
                                actionType: MainMenuActionType.tapShowDetailsView,
                                changeMenuViewTo: .tools
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.ToolsSection.Save,
                    description: getSaveSubmenuDescription(with: configuration),
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
                                actionType: MainMenuActionType.tapShowDetailsView,
                                changeMenuViewTo: .save
                            )
                        )
                    }
                )
            ]
        )
    }

    private func getToolsSubmenuDescription(with tabInfo: MainMenuTabInfo) -> String {
        typealias Preview = String.MainMenu.Submenus.Tools
        var description = ""

        description += "\(Preview.ZoomSubtitle)"

        // if tabInfo.readerModeIsAvailable {
        //     description += ", \(Preview.ReaderViewSubtitle)"
        // }

        description += ", \(Preview.NightModeSubtitle)"
        description += ", \(Preview.ReportBrokenSiteSubtitle)"
        description += ", \(Preview.ShareSubtitle)"

        return description
    }

    private func getSaveSubmenuDescription(with tabInfo: MainMenuTabInfo) -> String {
        typealias Preview = String.MainMenu.Submenus.Save
        var description = ""

        description += "\(Preview.BookmarkThisPageSubtitle)"
        description += ", \(Preview.AddToShortcutsSubtitle)"

        if tabInfo.readerModeIsAvailable {
            description += ", \(Preview.SaveToReadingListSubtitle)"
        }

        return description
    }

    private func configureUserAgentItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias Menu = String.MainMenu.ToolsSection
        typealias A11y = String.MainMenu.ToolsSection.AccessibilityLabels

        let title: String = if tabInfo.isDefaultUserAgentDesktop {
            tabInfo.hasChangedUserAgent ? Menu.SwitchToDesktopSite : Menu.SwitchToMobileSite
        } else {
            tabInfo.hasChangedUserAgent ? Menu.SwitchToMobileSite : Menu.SwitchToDesktopSite
        }

        let icon: String = if tabInfo.isDefaultUserAgentDesktop {
            tabInfo.hasChangedUserAgent ? Icons.deviceDesktop : Icons.deviceMobile
        } else {
            tabInfo.hasChangedUserAgent ? Icons.deviceMobile : Icons.deviceDesktop
        }

        let a11yLabel: String = if tabInfo.isDefaultUserAgentDesktop {
            tabInfo.hasChangedUserAgent ? A11y.SwitchToDesktopSite : A11y.SwitchToMobileSite
        } else {
            tabInfo.hasChangedUserAgent ? A11y.SwitchToMobileSite : A11y.SwitchToDesktopSite
        }

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: false,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.switchToDesktopSite,
            action: {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapToggleUserAgent
                    )
                )
            }
        )
    }

    // MARK: - Tools Submenu
    private func getToolsSubmenu(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo,
        and readerModeState: ReaderModeState?
    ) -> [MenuSection] {
        return [
            MenuSection(
                options: [
                    configureZoomItem(with: uuid, and: tabInfo),
                    configureNightModeItem(with: uuid),
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
                                    actionType: MainMenuActionType.tapNavigateToDestination,
                                    navigationDestination: MenuNavigationDestination(
                                        .goToURL,
                                        url: SupportUtils.URLForReportSiteIssue(tabInfo.url?.absoluteString)
                                    )
                                )
                            )
                        }
                    )
                ]
            ),
            MenuSection(
                options: [
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
                                    actionType: MainMenuActionType.tapNavigateToDestination,
                                    navigationDestination: MenuNavigationDestination(
                                        .shareSheet,
                                        url: tabInfo.canonicalURL
                                    )
                                )
                            )
                        }
                    )
                ]
            )
        ]
    }

    private func configureZoomItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        let zoomLevel = NumberFormatter.localizedString(
            from: NSNumber(value: tabInfo.zoomLevel),
            number: .percent
        )
        let title = String(format: .MainMenu.Submenus.Tools.Zoom, zoomLevel)
        let icon = tabInfo.zoomLevel == 1.0 ? Icons.zoomOff : Icons.zoomOn

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: tabInfo.zoomLevel != 1.0,
            a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.Zoom,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.zoom,
            action: {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuDetailsActionType.tapZoom
                    )
                )
            }
        )
    }

    private func configureReaderModeItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo,
        and readerModeState: ReaderModeState?
    ) -> MenuElement {
        typealias Strings = String.MainMenu.Submenus.Tools
        typealias A11y = String.MainMenu.Submenus.Tools.AccessibilityLabels

        let readerModeState = readerModeState ?? .unavailable
        let readerModeIsActive = readerModeState == .active
        let title = readerModeIsActive ? Strings.ReaderViewOff : Strings.ReaderViewOn
        let icon = readerModeIsActive ? Icons.readerViewOff : Icons.readerViewOn
        let a11yLabel = readerModeIsActive ? A11y.ReaderViewOff : A11y.ReaderViewOn

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: readerModeState != .unavailable,
            isActive: readerModeState == .active,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.readerView,
            action: {
                store.dispatch(
                    GeneralBrowserAction(
                        windowUUID: uuid,
                        actionType: GeneralBrowserActionType.showReaderMode
                    )
                )
            }
        )
    }

    private func configureNightModeItem(with uuid: WindowUUID) -> MenuElement {
        typealias Strings = String.MainMenu.Submenus.Tools
        typealias A11y = String.MainMenu.Submenus.Tools.AccessibilityLabels

        let nightModeIsOn = NightModeHelper.isActivated()
        let title = nightModeIsOn ? Strings.NightModeOff : Strings.NightModeOn
        let icon = nightModeIsOn ? Icons.nightModeOn : Icons.nightModeOff
        let a11yLabel = nightModeIsOn ? A11y.NightModeOff : A11y.NightModeOn

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: nightModeIsOn,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.nightMode,
            action: {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuDetailsActionType.tapToggleNightMode
                    )
                )
            }
        )
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
        let icon = tabInfo.isBookmarked ? Icons.editThisBookmark : Icons.bookmarkThisPage
        let a11yLabel = tabInfo.isBookmarked ? A11y.EditBookmark : A11y.BookmarkThisPage
        let actionType: MainMenuDetailsActionType = tabInfo.isBookmarked ? .tapEditBookmark : .tapAddToBookmarks

        return MenuElement(
            title: title,
            iconName: icon,
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
        let actionType: MainMenuDetailsActionType = tabInfo.isPinned ? .tapRemoveFromShortcuts : .tapAddToShortcuts

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

        let isInReadingList = tabInfo.isInReadingList
        let title = isInReadingList ? SaveMenu.RemoveFromReadingList : SaveMenu.SaveToReadingList
        let icon = isInReadingList ? Icons.removeFromReadingList : Icons.saveToReadingList
        let a11yLabel = isInReadingList ? A11y.RemoveFromReadingList : A11y.SaveToReadingList
        let actionType: MainMenuDetailsActionType = isInReadingList ? .tapRemoveFromReadingList : .tapAddToReadingList

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
                            actionType: MainMenuActionType.tapNavigateToDestination,
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
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
                a11yLabel: String(format: .MainMenu.OtherToolsSection.AccessibilityLabels.WhatsNew,
                                  AppName.shortName.rawValue),
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.whatsNew,
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(
                                .goToURL,
                                url: SupportUtils.URLForWhatsNew
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(
                                .goToURL,
                                url: SupportUtils.URLForGetHelp
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
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.settings)
                        )
                    )
                }
            )
        ]

        return MenuSection(options: isHomepage ? homepageOptions + standardOptions : standardOptions)
    }
}
