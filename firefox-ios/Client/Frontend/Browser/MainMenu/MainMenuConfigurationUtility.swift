// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Shared

struct MainMenuConfigurationUtility: Equatable, FeatureFlaggable {
    private struct Icons {
        static let newTab = StandardImageIdentifiers.Large.plus
        static let newPrivateTab = StandardImageIdentifiers.Large.privateModeCircleFill
        static let deviceDesktop = StandardImageIdentifiers.Large.deviceDesktop
        static let deviceMobile = StandardImageIdentifiers.Large.deviceMobile
        static let findInPage = StandardImageIdentifiers.Large.search
        static let tools = StandardImageIdentifiers.Large.tool
        static let save = StandardImageIdentifiers.Large.save
        static let bookmarks = StandardImageIdentifiers.Large.bookmarkTrayFill
        static let bookmarksTray = StandardImageIdentifiers.Large.bookmarkTray
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
        static let removeFromShortcuts = StandardImageIdentifiers.Large.pinSlashFill
        static let removeFromShortcutsV2 = StandardImageIdentifiers.Large.pinFill
        static let saveToReadingList = StandardImageIdentifiers.Large.readingListAdd
        static let removeFromReadingList = StandardImageIdentifiers.Large.readingListSlashFill
        static let bookmarkThisPage = StandardImageIdentifiers.Large.bookmark
        static let editThisBookmark = StandardImageIdentifiers.Large.bookmarkFill
        static let reportBrokenSite = StandardImageIdentifiers.Large.lightbulb
        static let customizeHomepage = StandardImageIdentifiers.Large.gridAdd
        static let saveAsPDF = StandardImageIdentifiers.Large.folder
        static let saveAsPDFV2 = StandardImageIdentifiers.Large.saveFile
        static let avatarCircle = StandardImageIdentifiers.Large.avatarCircle
        static let avatarWarningLargeLight = StandardImageIdentifiers.Large.avatarWarningCircleFillMulticolorLight
        static let avatarWarningLargeDark = StandardImageIdentifiers.Large.avatarWarningCircleFillMulticolorDark

        // These will be used in the future, but not now.
        // adding them just for completion's sake
        //        static let addToHomescreen = StandardImageIdentifiers.Large.addToHomescreen
    }

    private var shouldShowReportSiteIssue: Bool {
        featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly)
    }

    private var isNewAppearanceMenuOn: Bool {
        featureFlags.isFeatureEnabled(.appearanceMenu, checking: .buildOnly)
    }

    private var isMenuRedesignOn: Bool {
        featureFlags.isFeatureEnabled(.menuRedesign, checking: .buildOnly)
    }

    private var isDefaultZoomEnabled: Bool {
        featureFlags.isFeatureEnabled(.defaultZoomFeature, checking: .buildOnly)
    }

    public func generateMenuElements(
        with tabInfo: MainMenuTabInfo,
        for viewType: MainMenuDetailsViewType?,
        and uuid: WindowUUID,
        readerState: ReaderModeState? = nil,
        isExpanded: Bool = false
    ) -> [MenuSection] {
        switch viewType {
        case .tools:
            return getToolsSubmenu(with: uuid, tabInfo: tabInfo)

        case .save:
            return getSaveSubmenu(with: uuid, and: tabInfo)

        default:
            return getMainMenuElements(with: uuid, and: tabInfo, isExpanded: isExpanded)
        }
    }

    // MARK: - Main Menu

    private func getMainMenuElements(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo,
        isExpanded: Bool = false
    ) -> [MenuSection] {
        // Always include these sections
        var menuSections: [MenuSection] = []

        if !isMenuRedesignOn {
            menuSections.append(getNewTabSection(with: uuid, tabInfo: tabInfo))
            menuSections.append(getLibrariesSection(with: uuid, tabInfo: tabInfo))
            menuSections.append(
                getOtherToolsSection(
                    with: uuid,
                    isHomepage: tabInfo.isHomepage,
                    tabInfo: tabInfo
                ))
            // Conditionally add tools section if this is a website
            if !tabInfo.isHomepage {
                menuSections.insert(
                    getToolsSection(with: uuid, and: tabInfo),
                    at: 1
                )
            }
        } else if tabInfo.isHomepage {
            menuSections.append(getCustomiseHomepageSection(with: uuid, tabInfo: tabInfo))
            menuSections.append(getHorizontalTabsSection(with: uuid, tabInfo: tabInfo))
            menuSections.append(getAccountSection(with: uuid, tabInfo: tabInfo))
        } else {
            menuSections.append(getSiteSection(with: uuid, tabInfo: tabInfo, isExpanded: isExpanded))
            menuSections.append(getHorizontalTabsSection(with: uuid, tabInfo: tabInfo))
            menuSections.append(getAccountSection(with: uuid, tabInfo: tabInfo))
        }

        return menuSections
    }

    // MARK: - Menu Redesign Sections
    // Customise Homepage Section
    private func getCustomiseHomepageSection(with uuid: WindowUUID, tabInfo: MainMenuTabInfo) -> MenuSection {
        return MenuSection(
            isHomepage: tabInfo.isHomepage,
            options: [
                MenuElement(
                    title: .MainMenu.OtherToolsSection.CustomizeHomepage,
                    iconName: Icons.tools,
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: .MainMenu.OtherToolsSection.AccessibilityLabels.CustomizeHomepage,
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.customizeHomepage,
                    action: {
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(.customizeHomepage),
                                telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                            )
                        )
                    }
                ),
        ])
    }

    // Horizontal Tabs Section
    private func getHorizontalTabsSection(with uuid: WindowUUID, tabInfo: MainMenuTabInfo) -> MenuSection {
        return MenuSection(
            isHorizontalTabsSection: true,
            isHomepage: tabInfo.isHomepage,
            options: [
            MenuElement(
                title: .MainMenu.PanelLinkSection.History,
                iconName: Icons.history,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.PanelLinkSection.AccessibilityLabels.History,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.history,
                action: {
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.history),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.PanelLinkSection.Bookmarks,
                iconName: Icons.bookmarksTray,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.PanelLinkSection.AccessibilityLabels.Bookmarks,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.bookmarks,
                action: {
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.bookmarks),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.downloads),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.passwords),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                        )
                    )
                }
            ),
        ])
    }

    // Account Section
    private func getAccountSection(with uuid: WindowUUID, tabInfo: MainMenuTabInfo) -> MenuSection {
        return MenuSection(
            isHomepage: tabInfo.isHomepage,
            options: [
                MenuElement(
                    title: tabInfo.accountData.title,
                    description: tabInfo.accountData.subtitle,
                    iconName: Icons.avatarCircle,
                    iconImage: tabInfo.accountProfileImage,
                    needsReAuth: tabInfo.accountData.needsReAuth,
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.signIn,
                    action: {
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(.syncSignIn),
                                currentTabInfo: tabInfo
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
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(.settings),
                                telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                            )
                        )
                    }
                ),
        ])
    }

    // Site Section
    private func getSiteSection(with uuid: WindowUUID, tabInfo: MainMenuTabInfo, isExpanded: Bool) -> MenuSection {
        var options: [MenuElement] = [
            configureBookmarkPageItem(with: uuid, and: tabInfo),
            MenuElement(
                title: .MainMenu.ToolsSection.FindInPageV2,
                iconName: Icons.findInPage,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.FindInPage,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.findInPage,
                action: {
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.findInPage),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                        )
                    )
                }
            ),
            configureUserAgentItemV2(with: uuid, tabInfo: tabInfo)
        ]

        if !isExpanded {
            options.append(configureMoreLessItem(with: uuid, tabInfo: tabInfo, isExpanded: isExpanded))
        } else {
            options.append(contentsOf: [
                configureZoomItemV2(with: uuid, and: tabInfo),
                configureWebsiteDarkModeItem(with: uuid, and: tabInfo),
                configureShortcutsItemV2(with: uuid, and: tabInfo),
                MenuElement(
                    title: .MainMenu.Submenus.Save.SaveAsPDF,
                    iconName: Icons.saveAsPDFV2,
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: .MainMenu.Submenus.Save.AccessibilityLabels.SaveAsPDF,
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.saveAsPDF,
                    isOptional: true,
                    action: {
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(
                                    .saveAsPDF,
                                    url: tabInfo.canonicalURL
                                ),
                                telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.Submenus.Tools.Print,
                    iconName: Icons.print,
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.Print,
                    a11yHint: "",
                    a11yId: AccessibilityIdentifiers.MainMenu.print,
                    isOptional: true,
                    action: {
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(
                                    .printSheet,
                                    url: tabInfo.canonicalURL
                                ),
                                telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                            )
                        )
                    }
                ),
            ])
        }
        return MenuSection(isExpanded: isExpanded, options: options)
    }

    private func configureBookmarkPageItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias SaveMenu = String.MainMenu.Submenus.Save
        typealias A11y = SaveMenu.AccessibilityLabels

        let title = tabInfo.isBookmarked ? SaveMenu.EditBookmark : SaveMenu.BookmarkPage
        let icon = tabInfo.isBookmarked ? Icons.editThisBookmark : Icons.bookmarkThisPage
        let a11yLabel = tabInfo.isBookmarked ? A11y.EditBookmark : A11y.BookmarkPage
        let actionType: MainMenuActionType = tabInfo.isBookmarked ? .tapEditBookmark : .tapAddToBookmarks

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: tabInfo.isBookmarked,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.bookmarkPage,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    private func configureUserAgentItemV2(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        let isActive = tabInfo.isDefaultUserAgentDesktop ? !tabInfo.hasChangedUserAgent : tabInfo.hasChangedUserAgent
        return MenuElement(
            title: .MainMenu.ToolsSection.DesktopSite,
            iconName: "",
            isEnabled: true,
            isActive: isActive,
            a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.DesktopSite,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.desktopSite,
            infoTitle: isActive ? .MainMenu.On : .MainMenu.Off,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapToggleUserAgent,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage,
                                                     isDefaultUserAgentDesktop: tabInfo.isDefaultUserAgentDesktop,
                                                     hasChangedUserAgent: tabInfo.hasChangedUserAgent)
                    )
                )
            }
        )
    }

    private func configureMoreLessItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo,
        isExpanded: Bool
    ) -> MenuElement {
        typealias Menu = String.MainMenu.ToolsSection
        typealias A11y = String.MainMenu.ToolsSection.AccessibilityLabels
        typealias Icons = StandardImageIdentifiers.Large

        return MenuElement(
            title: isExpanded ? Menu.LessOptions : Menu.MoreOptions,
            iconName: isExpanded ? Icons.chevronDown : Icons.chevronRight,
            isEnabled: true,
            isActive: false,
            a11yLabel: isExpanded ? A11y.LessOptions : A11y.MoreOptions,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.moreLess,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapMoreOptions,
                        isExpanded: isExpanded
                    )
                )
            }
        )
    }

    private func configureZoomItemV2(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        let zoomLevel = NumberFormatter.localizedString(
            from: NSNumber(value: tabInfo.zoomLevel),
            number: .percent
        )

        let regularZoom: CGFloat = 1.0
        let zoomSymbol: String = if tabInfo.zoomLevel > regularZoom {
            .MainMenu.Submenus.Tools.ZoomPositiveSymbol
        } else if tabInfo.zoomLevel < regularZoom {
            .MainMenu.Submenus.Tools.ZoomNegativeSymbol
        } else {
            ""
        }

        return MenuElement(
            title: .MainMenu.Submenus.Tools.PageZoomV2,
            iconName: "",
            isEnabled: true,
            isActive: tabInfo.zoomLevel != regularZoom,
            a11yLabel: String(format: .MainMenu.Submenus.Tools.AccessibilityLabels.Zoom, "\(zoomSymbol)\(zoomLevel)"),
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.zoom,
            isOptional: true,
            infoTitle: "\(zoomLevel)",
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapZoom,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    private func configureWebsiteDarkModeItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias A11y = String.MainMenu.Submenus.Tools.AccessibilityLabels

        let nightModeIsOn = NightModeHelper.isActivated()
        let a11yLabel = nightModeIsOn ? A11y.NightModeOff : A11y.NightModeOn

        return MenuElement(
            title: .MainMenu.Submenus.Tools.WebsiteDarkMode,
            iconName: "",
            isEnabled: true,
            isActive: nightModeIsOn,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.nightMode,
            isOptional: true,
            infoTitle: nightModeIsOn ? .MainMenu.On : .MainMenu.Off,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapToggleNightMode,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage,
                                                     isActionOn: nightModeIsOn)
                    )
                )
            }
        )
    }

    private func configureShortcutsItemV2(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias SaveMenu = String.MainMenu.Submenus.Save
        typealias A11y = SaveMenu.AccessibilityLabels

        let title = tabInfo.isPinned ? SaveMenu.RemoveFromShortcuts : SaveMenu.AddToShortcuts
        let icon = tabInfo.isPinned ? Icons.removeFromShortcutsV2 : Icons.addToShortcuts
        let a11yLabel = tabInfo.isPinned ? A11y.RemoveFromShortcuts : A11y.AddToShortcuts

        let actionType: MainMenuActionType = tabInfo.isPinned ? .tapRemoveFromShortcuts : .tapAddToShortcuts

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: tabInfo.isPinned,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.addToShortcuts,
            isOptional: true,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    // MARK: - New Tabs Section
    private func getNewTabSection(with uuid: WindowUUID, tabInfo: MainMenuTabInfo) -> MenuSection {
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.newTab),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.newPrivateTab),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                        )
                    )
                }
            ),
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
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapNavigateToDestination,
                                navigationDestination: MenuNavigationDestination(.findInPage),
                                telemetryInfo: TelemetryInfo(isHomepage: configuration.isHomepage)
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
                    a11yHint: getToolsSubmenuDescription(with: configuration),
                    a11yId: AccessibilityIdentifiers.MainMenu.tools,
                    action: {
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapShowDetailsView,
                                changeMenuViewTo: .tools,
                                telemetryInfo: TelemetryInfo(isHomepage: configuration.isHomepage)
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
                    a11yHint: getSaveSubmenuDescription(with: configuration),
                    a11yId: AccessibilityIdentifiers.MainMenu.save,
                    action: {
                        store.dispatchLegacy(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.tapShowDetailsView,
                                changeMenuViewTo: .save,
                                telemetryInfo: TelemetryInfo(isHomepage: configuration.isHomepage)
                            )
                        )
                    }
                ),
            ]
        )
    }

    private func getToolsSubmenuDescription(with _: MainMenuTabInfo) -> String {
        typealias Preview = String.MainMenu.Submenus.Tools
        var description = ""

        description += "\(Preview.ZoomSubtitle)"

        // if tabInfo.readerModeIsAvailable {
        //     description += ", \(Preview.ReaderViewSubtitle)"
        // }

        description += ", \(Preview.NightModeSubtitle)"
        if shouldShowReportSiteIssue {
            description += ", \(Preview.ReportBrokenSiteSubtitle)"
        }

        description += ", \(Preview.PrintSubtitle)"
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

        description += ", \(Preview.SaveAsPDFSubtitle)"

        return description
    }

    private func configureUserAgentItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        typealias Menu = String.MainMenu.ToolsSection
        typealias A11y = String.MainMenu.ToolsSection.AccessibilityLabels

        // isDefaultUserAgentDesktop is only true if we're building on an "intel mac"
        // hasChangedUserAgent describes if we've changed form the initial starting state
        let userAgentStringSelector = { (desktopString: String, mobileString: String) in
            tabInfo.isDefaultUserAgentDesktop == tabInfo.hasChangedUserAgent ? desktopString : mobileString
        }

        let title = userAgentStringSelector(Menu.SwitchToDesktopSite, Menu.SwitchToMobileSite)
        let icon = userAgentStringSelector(Icons.deviceDesktop, Icons.deviceMobile)
        let a11yLabel = userAgentStringSelector(A11y.SwitchToDesktopSite, A11y.SwitchToMobileSite)

        let isActive = tabInfo.isDefaultUserAgentDesktop ? !tabInfo.hasChangedUserAgent : tabInfo.hasChangedUserAgent

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: isActive,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.switchToDesktopSite,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapToggleUserAgent,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage,
                                                     isDefaultUserAgentDesktop: tabInfo.isDefaultUserAgentDesktop,
                                                     hasChangedUserAgent: tabInfo.hasChangedUserAgent)
                    )
                )
            }
        )
    }

    // MARK: - Tools Submenu

    private func getToolsSubmenu(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> [MenuSection] {
        let firstSection = if shouldShowReportSiteIssue {
            MenuSection(options: [
                configureZoomItem(with: uuid, and: tabInfo),
                configureNightModeItem(with: uuid, and: tabInfo),
                configureReportSiteIssueItem(with: uuid, tabInfo: tabInfo),
            ])
        } else {
            MenuSection(options: [
                configureZoomItem(with: uuid, and: tabInfo),
                configureNightModeItem(with: uuid, and: tabInfo),
            ])
        }

        return [
            firstSection,
            MenuSection(options: [
                configurePrintItem(with: uuid, tabInfo: tabInfo),
                configureShareItem(with: uuid, tabInfo: tabInfo),
            ])
        ]
    }

    private func configureReportSiteIssueItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        return MenuElement(
            title: .MainMenu.Submenus.Tools.ReportBrokenSite,
            iconName: Icons.reportBrokenSite,
            isEnabled: true,
            isActive: false,
            a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.ReportBrokenSite,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.reportBrokenSite,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapNavigateToDestination,
                        navigationDestination: MenuNavigationDestination(
                            .goToURL,
                            url: SupportUtils.URLForReportSiteIssue(tabInfo.url?.absoluteString)
                        ),
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    private func configurePrintItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        return MenuElement(
            title: .MainMenu.Submenus.Tools.Print,
            iconName: Icons.print,
            isEnabled: true,
            isActive: false,
            a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.Print,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.print,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapNavigateToDestination,
                        navigationDestination: MenuNavigationDestination(
                            .printSheet,
                            url: tabInfo.canonicalURL
                        ),
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    private func configureShareItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        return MenuElement(
            title: .MainMenu.Submenus.Tools.Share,
            iconName: Icons.share,
            isEnabled: true,
            isActive: false,
            a11yLabel: .MainMenu.Submenus.Tools.AccessibilityLabels.Share,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.share,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapNavigateToDestination,
                        navigationDestination: MenuNavigationDestination(
                            .shareSheet,
                            url: tabInfo.canonicalURL
                        ),
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    private func configureZoomItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        let zoomLevel = NumberFormatter.localizedString(
            from: NSNumber(value: tabInfo.zoomLevel),
            number: .percent
        )

        let regularZoom: CGFloat = 1.0
        let zoomSymbol: String = if tabInfo.zoomLevel > regularZoom {
            .MainMenu.Submenus.Tools.ZoomPositiveSymbol
        } else if tabInfo.zoomLevel < regularZoom {
            .MainMenu.Submenus.Tools.ZoomNegativeSymbol
        } else {
            ""
        }

        let formattableString: String = isDefaultZoomEnabled ?
            .MainMenu.Submenus.Tools.PageZoom :
            .MainMenu.Submenus.Tools.Zoom
        let title = String(format: formattableString, "\(zoomSymbol)\(zoomLevel)")
        let icon = tabInfo.zoomLevel == regularZoom ? Icons.zoomOff : Icons.zoomOn

        return MenuElement(
            title: title,
            iconName: icon,
            isEnabled: true,
            isActive: tabInfo.zoomLevel != regularZoom,
            a11yLabel: String(format: .MainMenu.Submenus.Tools.AccessibilityLabels.Zoom, "\(zoomSymbol)\(zoomLevel)"),
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.zoom,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuDetailsActionType.tapZoom,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
            a11yHint: readerModeState != .unavailable ? "" : .MainMenu.AccessibilityLabels.OptionDisabledHint,
            a11yId: AccessibilityIdentifiers.MainMenu.readerView,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: GeneralBrowserActionType.showReaderMode,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage,
                                                     isActionOn: readerModeState == .active)
                    )
                )
                store.dispatchLegacy(
                    GeneralBrowserAction(
                        windowUUID: uuid,
                        actionType: GeneralBrowserActionType.showReaderMode
                    )
                )
            }
        )
    }

    private func getNightModeTitle(_ isNightModeOn: Bool) -> String {
        if isNewAppearanceMenuOn {
            return isNightModeOn
                ? .MainMenu.Submenus.Tools.WebsiteDarkModeOff
                : .MainMenu.Submenus.Tools.WebsiteDarkModeOn
        } else {
            return isNightModeOn
                ? .MainMenu.Submenus.Tools.NightModeOff
                : .MainMenu.Submenus.Tools.NightModeOn
        }
    }

    private func configureNightModeItem(with uuid: WindowUUID, and tabInfo: MainMenuTabInfo) -> MenuElement {
        typealias A11y = String.MainMenu.Submenus.Tools.AccessibilityLabels

        let nightModeIsOn = NightModeHelper.isActivated()
        let icon = nightModeIsOn ? Icons.nightModeOn : Icons.nightModeOff
        let a11yLabel = nightModeIsOn ? A11y.NightModeOff : A11y.NightModeOn

        return MenuElement(
            title: getNightModeTitle(nightModeIsOn),
            iconName: icon,
            isEnabled: true,
            isActive: nightModeIsOn,
            a11yLabel: a11yLabel,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.nightMode,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuDetailsActionType.tapToggleNightMode,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage,
                                                     isActionOn: nightModeIsOn)
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
                configureReadingListItem(with: uuid, and: tabInfo),
                configureSaveAsPDFItem(with: uuid, and: tabInfo),
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
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
            a11yHint: tabInfo.readerModeIsAvailable ? "" : .MainMenu.AccessibilityLabels.OptionDisabledHint,
            a11yId: AccessibilityIdentifiers.MainMenu.saveToReadingList,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: actionType,
                        tabID: tabInfo.tabID,
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    private func configureSaveAsPDFItem(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo
    ) -> MenuElement {
        return MenuElement(
            title: .MainMenu.Submenus.Save.SaveAsPDF,
            iconName: Icons.saveAsPDF,
            isEnabled: true,
            isActive: false,
            a11yLabel: .MainMenu.Submenus.Save.AccessibilityLabels.SaveAsPDF,
            a11yHint: "",
            a11yId: AccessibilityIdentifiers.MainMenu.saveAsPDF,
            action: {
                store.dispatchLegacy(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.tapNavigateToDestination,
                        navigationDestination: MenuNavigationDestination(
                            .saveAsPDF,
                            url: tabInfo.canonicalURL
                        ),
                        telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                    )
                )
            }
        )
    }

    // MARK: - Libraries Section
    private func getLibrariesSection(with uuid: WindowUUID, tabInfo: MainMenuTabInfo) -> MenuSection {
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.bookmarks),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.history),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.downloads),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.passwords),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                        )
                    )
                }
            ),
        ])
    }

    // MARK: - Other Tools Section

    private func getOtherToolsSection(
        with uuid: WindowUUID,
        isHomepage: Bool,
        tabInfo: MainMenuTabInfo
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.customizeHomepage),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                a11yLabel: String(
                    format: .MainMenu.OtherToolsSection.AccessibilityLabels.WhatsNew,
                    AppName.shortName.rawValue
                ),
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.whatsNew,
                action: {
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(
                                .goToURL,
                                url: SupportUtils.URLForWhatsNew
                            ),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                        )
                    )
                }
            ),
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(
                                .goToURL,
                                url: SupportUtils.URLForGetHelp
                            ),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.settings),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
                        )
                    )
                }
            ),
        ]

        return MenuSection(options: isHomepage ? homepageOptions + standardOptions : standardOptions)
    }
}
