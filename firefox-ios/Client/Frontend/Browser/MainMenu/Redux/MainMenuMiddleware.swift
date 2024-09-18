// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

final class MainMenuMiddleware {
    private let logger: Logger
    private let telemetry = MainMenuTelemetry()

    var currentTabInfo: MainMenuTabInfo?
    var submenuToDisplay: MainMenuDetailsViewType?

    init(
        logger: Logger = DefaultLogger.shared
    ) {
        self.logger = logger
        self.currentTabInfo = nil
    }

    lazy var mainMenuProvider: Middleware<AppState> = { state, action in
        guard let action = action as? MainMenuAction else { return }

        if action.actionType is MainMenuActionType {
            self.resolveMainMenuActionTypeActions(action: action, state: state)
        } else if action.actionType is MainMenuDetailsActionType {
            self.resolveMainMenuDetailsActionTypeActions(action: action, state: state)
        } else if action.actionType is MainMenuMiddlewareActionType {
            self.resolveMainMenuMiddlewareActionTypeActions(action: action, state: state)
        }
    }

    private func resolveMainMenuActionTypeActions(action: MainMenuAction, state: AppState) {
        switch action.actionType {
        case MainMenuActionType.closeMenu:
            self.telemetry.mainMenuDismissed()
        case MainMenuActionType.mainMenuDidAppear:
            self.telemetry.mainMenuViewed()
        case MainMenuActionType.viewDidLoad:
            self.performViewDidLoadFlow(with: action.windowUUID)
        case MainMenuActionType.viewWillDisappear:
            self.currentTabInfo = nil
        default:
            break
        }
    }

    private func resolveMainMenuDetailsActionTypeActions(action: MainMenuAction, state: AppState) {
        switch action.actionType {
        case MainMenuDetailsActionType.viewDidLoad:
            self.performViewDidLoadFlow(with: action.windowUUID)
            self.dispatchSubmenuType(with: action.windowUUID)
        case MainMenuDetailsActionType.viewDidDisappear:
            self.submenuToDisplay = nil
        default:
            break
        }
    }

    private func resolveMainMenuMiddlewareActionTypeActions(action: MainMenuAction, state: AppState) {
        switch action.actionType {
        case MainMenuMiddlewareActionType.updateSubmenuTypeTo(let submenuType):
            self.submenuToDisplay = submenuType
            self.dispatchSubmenuType(with: action.windowUUID)
        case MainMenuMiddlewareActionType.provideTabInfo(let info):
            if let info {
                self.currentTabInfo = info
                self.dispatchTabInfo(with: action.windowUUID, and: info)
            }
        default:
            break
        }
    }

    private func performViewDidLoadFlow(with uuid: WindowUUID) {
        if let currentTabInfo {
            self.dispatchTabInfo(with: uuid, and: currentTabInfo)
        } else {
            store.dispatch(
                MainMenuAction(
                    windowUUID: uuid,
                    actionType: MainMenuMiddlewareActionType.requestTabInfo
                )
            )
        }
    }

    private func dispatchTabInfo(
        with windowUUID: WindowUUID,
        and info: MainMenuTabInfo
    ) {
        store.dispatch(
            MainMenuAction(
                windowUUID: windowUUID,
                actionType: MainMenuActionType.updateCurrentTabInfo(info)
            )
        )
    }

    private func dispatchSubmenuType(with windowUUID: WindowUUID) {
        if let submenuToDisplay {
            store.dispatch(
                MainMenuAction(
                    windowUUID: windowUUID,
                    actionType: MainMenuDetailsActionType.updateSubmenuType(submenuToDisplay)
                )
            )
        }
    }
}
