// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Shared

struct MainMenuConfigurationUtility: Equatable, FeatureFlaggable {
    private struct Icons {
        static let findInPage = StandardImageIdentifiers.Large.search
        static let bookmarksTray = StandardImageIdentifiers.Large.bookmarkTray
        static let history = StandardImageIdentifiers.Large.history
        static let downloads = StandardImageIdentifiers.Large.download
        static let passwords = StandardImageIdentifiers.Large.login
        static let settings = StandardImageIdentifiers.Large.settings
        static let print = StandardImageIdentifiers.Large.print
        static let addToShortcuts = StandardImageIdentifiers.Large.pin
        static let removeFromShortcutsV2 = StandardImageIdentifiers.Large.pinFill
        static let bookmarkThisPage = StandardImageIdentifiers.Large.bookmark
        static let editThisBookmark = StandardImageIdentifiers.Large.bookmarkFill
        static let saveAsPDFV2 = StandardImageIdentifiers.Large.saveFile
        static let summarizer = StandardImageIdentifiers.Large.summarizer
        static let avatarCircle = StandardImageIdentifiers.Large.avatarCircle
    }

    private var shouldShowReportSiteIssue: Bool {
        featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly)
    }

    private var isNewAppearanceMenuOn: Bool {
        featureFlags.isFeatureEnabled(.appearanceMenu, checking: .buildOnly)
    }

    private var isSummarizerOn: Bool {
        return DefaultSummarizerNimbusUtils().isSummarizeFeatureToggledOn
    }

    private var isDefaultZoomEnabled: Bool {
        featureFlags.isFeatureEnabled(.defaultZoomFeature, checking: .buildOnly)
    }

    public func generateMenuElements(
        with tabInfo: MainMenuTabInfo,
        and uuid: WindowUUID,
        isExpanded: Bool = false
    ) -> [MenuSection] {
        return getMainMenuElements(with: uuid, and: tabInfo, isExpanded: isExpanded)
    }

    // MARK: - Main Menu

    private func getMainMenuElements(
        with uuid: WindowUUID,
        and tabInfo: MainMenuTabInfo,
        isExpanded: Bool = false
    ) -> [MenuSection] {
        // Always include these sections
        var menuSections: [MenuSection] = []

        if tabInfo.isHomepage {
            menuSections.append(getHorizontalTabsSection(with: uuid, tabInfo: tabInfo))
            menuSections.append(getAccountSection(with: uuid, tabInfo: tabInfo))
        } else {
            menuSections.append(getSiteSection(with: uuid, tabInfo: tabInfo, isExpanded: isExpanded))
            menuSections.append(getHorizontalTabsSection(with: uuid, tabInfo: tabInfo))
            menuSections.append(getAccountSection(with: uuid, tabInfo: tabInfo))
        }

        return menuSections
    }

    // MARK: - Menu Sections
    // Horizontal Tabs Section
    private func getHorizontalTabsSection(with uuid: WindowUUID, tabInfo: MainMenuTabInfo) -> MenuSection {
        return MenuSection(
            isHorizontalTabsSection: true,
            groupA11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.LibraryOptions,
            isHomepage: tabInfo.isHomepage,
            options: [
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
                    a11yLabel: "\(tabInfo.accountData.title) \(tabInfo.accountData.subtitle ?? "")",
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
        ]
        // Conditionally add the Summarizer item if the feature is enabled
        if isSummarizerOn, tabInfo.summaryIsAvailable {
            options.append(configureSummarizerItem(with: uuid, tabInfo: tabInfo))
        }
        options.append(configureUserAgentItemV2(with: uuid, tabInfo: tabInfo))

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
                                    .saveAsPDFV2,
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
                                    .printSheetV2,
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
            a11yHint: isActive ? .MainMenu.ToolsSection.DesktopSiteOn : .MainMenu.ToolsSection.DesktopSiteOff,
            a11yId: AccessibilityIdentifiers.MainMenu.desktopSite,
            infoTitle: isActive ? .MainMenu.ToolsSection.DesktopSiteOn : .MainMenu.ToolsSection.DesktopSiteOff,
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

    private func configureSummarizerItem(
        with uuid: WindowUUID,
        tabInfo: MainMenuTabInfo
    ) -> MenuElement {
            return MenuElement(
                title: .MainMenu.ToolsSection.SummarizePage,
                iconName: Icons.summarizer,
                isEnabled: true,
                isActive: false,
                a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.SummarizePage,
                a11yHint: "",
                a11yId: AccessibilityIdentifiers.MainMenu.summarizePage,
                action: {
                    store.dispatchLegacy(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.tapNavigateToDestination,
                            navigationDestination: MenuNavigationDestination(.webpageSummary(config: tabInfo.summarizerConfig)),
                            telemetryInfo: TelemetryInfo(isHomepage: tabInfo.isHomepage)
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
            a11yHint: isExpanded ? A11y.ExpandedHint : A11y.CollapsedHint,
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
            a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.PageZoom,
            a11yHint: "\(zoomSymbol)\(zoomLevel)",
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
        typealias Tools = String.MainMenu.Submenus.Tools

        let nightModeIsOn = NightModeHelper.isActivated()

        return MenuElement(
            title: .MainMenu.Submenus.Tools.WebsiteDarkMode,
            iconName: "",
            isEnabled: true,
            isActive: nightModeIsOn,
            a11yLabel: .MainMenu.ToolsSection.AccessibilityLabels.WebsiteDarkMode,
            a11yHint: nightModeIsOn ? Tools.WebsiteDarkModeOnV2 : Tools.WebsiteDarkModeOffV2,
            a11yId: AccessibilityIdentifiers.MainMenu.nightMode,
            isOptional: true,
            infoTitle: nightModeIsOn ? Tools.WebsiteDarkModeOnV2 : Tools.WebsiteDarkModeOffV2,
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
}
