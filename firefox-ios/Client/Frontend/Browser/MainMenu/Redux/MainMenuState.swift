// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Shared
import Redux

struct MainMenuState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var menuElements: [[MenuElement]]
    var navigationDestination: MainMenuNavigationDestination?
    var shouldDismiss: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let mainMenuState = store.state.screenState(
            MainMenuState.self,
            for: .mainMenu,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: mainMenuState.windowUUID,
            menuElements: mainMenuState.menuElements,
            navigationDestination: mainMenuState.navigationDestination,
            shouldDismiss: mainMenuState.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            navigationDestination: nil,
            shouldDismiss: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [[MenuElement]],
        navigationDestination: MainMenuNavigationDestination? = nil,
        shouldDismiss: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case MainMenuActionType.viewDidLoad:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: MainMenuConfigurationUtility().populateMenuElements(with: state.windowUUID)
            )
        case MainMenuActionType.showSettings:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: MainMenuConfigurationUtility().populateMenuElements(with: state.windowUUID),
                navigationDestination: .settings
            )
        case MainMenuActionType.closeMenu:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                shouldDismiss: true
            )
        default:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                navigationDestination: state.navigationDestination,
                shouldDismiss: state.shouldDismiss
            )
        }
    }
}

struct MainMenuConfigurationUtility {
    func populateMenuElements(with uuid: WindowUUID) -> [[MenuElement]] {
        return [
            getNewTabSection(with: uuid),
            getPageToolsSection(with: uuid),
            getLibrariesSection(with: uuid),
            getOtherToolsSection(with: uuid)
        ]
    }

    private func getNewTabSection(
        with uuid: WindowUUID
    ) -> [MenuElement] {
        return [
            MenuElement(
                title: "Test title",
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
                title: "Test title",
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
    }

    private func getLibrariesSection(
        with uuid: WindowUUID
    ) -> [MenuElement] {
        return [
            MenuElement(
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
    }

    private func getPageToolsSection(
        with uuid: WindowUUID
    ) -> [MenuElement] {
        return [
            MenuElement(
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
    }

    private func getOtherToolsSection(
        with uuid: WindowUUID
    ) -> [MenuElement] {
        return [
            MenuElement(
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
                            actionType: MainMenuActionType.showSettings
                        )
                    )
                }
            )
        ]
    }

    private func getToolsSubmenu(
        with uuid: WindowUUID
    ) -> [MenuElement] {
        return [
            MenuElement(
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
    }

    private func getSaveSumbenu(
        with uuid: WindowUUID
    ) -> [MenuElement] {
        return [
            MenuElement(
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
                title: "Test title",
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
    }
}
