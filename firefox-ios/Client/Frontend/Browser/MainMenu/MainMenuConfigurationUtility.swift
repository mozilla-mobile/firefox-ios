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
                            actionType: MainMenuActionType.show(.newTab)
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
                            actionType: MainMenuActionType.show(.newPrivateTab)
                        )
                    )
                }
            )
        ])
    }

    private func getToolsSection(
        with uuid: WindowUUID,
        and configuration: MainMenuTabInfo?
    ) -> MenuSection {
        // Configuration can be `nil` if Redux hasn't yet returned the
        // required information about the tab.
        guard let configuration else { return MenuSection(options: []) }

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
                                actionType: MainMenuActionType.show(.findInPage)
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
                                actionType: MainMenuActionType.closeMenu
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
                                actionType: MainMenuActionType.closeMenu
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

        // Our default User Agest gets set depending on the architecture we're
        // running on. Thus, to determine which string to use, we need to know
        //   1) which architecture we've started from and
        //   2) whether or not we've requested to change the user agent in the tab
        // Using this information, we're able to present the correct string for
        // the "Request Mobile/Desktop Site" menu option
        let switchToDesktop = tabHasChangedUserAgent ? defaultIsDesktop : !defaultIsDesktop
        return switchToDesktop ? Menu.SwitchToDesktopSite : Menu.SwitchToMobileSite
    }

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
                            actionType: MainMenuActionType.show(.bookmarks)
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
                            actionType: MainMenuActionType.show(.history)
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
                            actionType: MainMenuActionType.show(.downloads)
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
                            actionType: MainMenuActionType.show(.passwords)
                        )
                    )
                }
            )
        ])
    }

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
                            actionType: MainMenuActionType.show(.customizeHomepage)
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
                            actionType: MainMenuActionType.show(.goToURL(SupportUtils.URLForWhatsNew))
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
                            actionType: MainMenuActionType.show(.goToURL(SupportUtils.URLForGetHelp))
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
                            actionType: MainMenuActionType.show(.settings)
                        )
                    )
                }
            )
        ]

        return MenuSection(options: isHomepage ? homepageOptions + standardOptions : standardOptions)
    }
}
