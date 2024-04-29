// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

class ToolbarMiddleware: FeatureFlaggable {
    private let profile: Profile
    private let manager: ToolbarManager
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         manager: ToolbarManager = DefaultToolbarManager(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.manager = manager
        self.logger = logger
    }

    lazy var toolbarProvider: Middleware<AppState> = { [self] state, action in
        let uuid = action.windowUUID
        switch action {
        case GeneralBrowserAction.browserDidLoad(let context):
            let actions = self.loadNavigationToolbarElements()
            let displayBorder = self.shouldDisplayNavigationToolbarBorder(state: state, windowUUID: action.windowUUID)
            let context = ToolbarNavigationModelContext(actions: actions,
                                                        displayBorder: displayBorder,
                                                        windowUUID: uuid)
            store.dispatch(ToolbarAction.didLoadToolbars(context))

        default:
            break
        }
    }

    private func loadNavigationToolbarElements() -> [ToolbarState.ActionState] {
        var elements = [ToolbarState.ActionState]()
        elements.append(ToolbarState.ActionState(actionType: .back,
                                                 iconName: StandardImageIdentifiers.Large.back,
                                                 isEnabled: false,
                                                 a11yLabel: .TabToolbarBackAccessibilityLabel,
                                                 a11yId: AccessibilityIdentifiers.Toolbar.backButton))
        elements.append(ToolbarState.ActionState(actionType: .forward,
                                                 iconName: StandardImageIdentifiers.Large.forward,
                                                 isEnabled: false,
                                                 a11yLabel: .TabToolbarForwardAccessibilityLabel,
                                                 a11yId: AccessibilityIdentifiers.Toolbar.forwardButton))
        elements.append(ToolbarState.ActionState(actionType: .home,
                                                 iconName: StandardImageIdentifiers.Large.home,
                                                 isEnabled: true,
                                                 a11yLabel: .TabToolbarHomeAccessibilityLabel,
                                                 a11yId: AccessibilityIdentifiers.Toolbar.homeButton))
        elements.append(ToolbarState.ActionState(actionType: .tabs,
                                                 iconName: StandardImageIdentifiers.Large.tabTray, // correct image
                                                 isEnabled: true,
                                                 a11yLabel: .TabsButtonShowTabsAccessibilityLabel,
                                                 a11yId: AccessibilityIdentifiers.Toolbar.tabsButton))
        elements.append(ToolbarState.ActionState(actionType: .menu,
                                                 iconName: StandardImageIdentifiers.Large.appMenu,
                                                 isEnabled: true,
                                                 a11yLabel: .AppMenu.Toolbar.MenuButtonAccessibilityLabel,
                                                 a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton))
        return elements
    }

    private func shouldDisplayNavigationToolbarBorder(state: AppState, windowUUID: UUID) -> Bool {
        guard let browserState = state.screenState(BrowserViewControllerState.self,
                                                   for: .browserViewController,
                                                   window: windowUUID) else { return false }
        let toolbarState = browserState.toolbarState
        return manager.shouldDisplayNavigationBorder(toolbarPosition: toolbarState.toolbarPosition)
    }
}
