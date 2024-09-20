// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Shared

struct MainMenuConfigurationUtility: Equatable {
    func generateMenuElements(
        with uuid: WindowUUID,
        andInfo configuration: MainMenuTabInfo?
    ) -> [MenuSection] {
        // Always include these sections
        var menuSections: [MenuSection] = [
            getNewTabSection(with: uuid),
            getLibrariesSection(with: uuid),
            getOtherToolsSection(
                with: uuid,
                isHomepage: configuration?.isHomepage ?? false
            )
        ]

        // Conditionally add tools section if this is a website
        if let configuration, !configuration.isHomepage {
            menuSections.insert(
                getToolsSection(with: uuid, and: configuration),
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
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .newTab
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.TabsSection.NewPrivateTab,
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .newPrivateTab
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
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
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
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.show,
                                navigationDestination: .findInPage
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.ToolsSection.Tools,
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.show,
                                navigationDestination: .detailsView(with: getToolsSubmenu(with: uuid))
                            )
                        )
                    }
                ),
                MenuElement(
                    title: .MainMenu.ToolsSection.Save,
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.show,
                                navigationDestination: .detailsView(with: getSaveSubmenu(with: uuid))
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

    private func getToolsSubmenu(with uuid: WindowUUID) -> [MenuSection] {
        return [
            MenuSection(
                options: [
                    MenuElement(
                        title: .MainMenu.Submenus.Tools.Zoom,
                        iconName: "",
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: "",
                        a11yHint: "",
                        a11yId: "",
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
                        iconName: "",
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: "",
                        a11yHint: "",
                        a11yId: "",
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
                        iconName: "",
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: "",
                        a11yHint: "",
                        a11yId: "",
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
                        iconName: "",
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: "",
                        a11yHint: "",
                        a11yId: "",
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
                        iconName: "",
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: "",
                        a11yHint: "",
                        a11yId: "",
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
                        iconName: "",
                        isEnabled: true,
                        isActive: false,
                        a11yLabel: "",
                        a11yHint: "",
                        a11yId: "",
                        action: {
                            store.dispatch(
                                MainMenuAction(
                                    windowUUID: uuid,
                                    actionType: MainMenuActionType.closeMenu
                                )
                            )
                        }
                    ),
                ]
            )
        ]
    }

    private func getSaveSubmenu(with uuid: WindowUUID) -> [MenuSection] {
        return [MenuSection(
            options: [
                MenuElement(
                    title: .MainMenu.Submenus.Save.BookmarkThisPage,
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
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
                    title: .MainMenu.Submenus.Save.AddToShortcuts,
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
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
                    title: .MainMenu.Submenus.Save.AddToHomeScreen,
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
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
                    title: .MainMenu.Submenus.Save.SaveToReadingList,
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
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
                    title: .MainMenu.Submenus.Save.SaveAsPDF,
                    iconName: "",
                    isEnabled: true,
                    isActive: false,
                    a11yLabel: "",
                    a11yHint: "",
                    a11yId: "",
                    action: {
                        store.dispatch(
                            MainMenuAction(
                                windowUUID: uuid,
                                actionType: MainMenuActionType.closeMenu
                            )
                        )
                    }
                ),
            ]
        )]
    }

    // MARK: - Libraries Section
    private func getLibrariesSection(with uuid: WindowUUID) -> MenuSection {
        return MenuSection(options: [
            MenuElement(
                title: .MainMenu.PanelLinkSection.Bookmarks,
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .bookmarks
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.PanelLinkSection.History,
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .history
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.PanelLinkSection.Downloads,
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .downloads
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.PanelLinkSection.Passwords,
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .passwords
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
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .customizeHomepage
                        )
                    )
                }
            ),
            MenuElement(
                title: String(
                    format: .MainMenu.OtherToolsSection.WhatsNew,
                    AppName.shortName.rawValue
                ),
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .goToURL(SupportUtils.URLForWhatsNew)
                        )
                    )
                }
            )
        ]

        let standardOptions = [
            MenuElement(
                title: .MainMenu.OtherToolsSection.GetHelp,
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .goToURL(SupportUtils.URLForGetHelp)
                        )
                    )
                }
            ),
            MenuElement(
                title: .MainMenu.OtherToolsSection.Settings,
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: {
                    store.dispatch(
                        MainMenuAction(
                            windowUUID: uuid,
                            actionType: MainMenuActionType.show,
                            navigationDestination: .settings
                        )
                    )
                }
            )
        ]

        return MenuSection(options: isHomepage ? homepageOptions + standardOptions : standardOptions)
    }
}
