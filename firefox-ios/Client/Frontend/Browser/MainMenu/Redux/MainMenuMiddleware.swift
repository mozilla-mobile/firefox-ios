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
        switch action.actionType {
        case MainMenuActionType.viewDidLoad:
            self.performViewDidLoadFlow(with: action.windowUUID)
        case MainMenuDetailsActionType.viewDidLoad:
            self.performViewDidLoadFlow(with: action.windowUUID)

            if let submenuType = self.submenuToDisplay {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: action.windowUUID,
                        actionType: MainMenuDetailsActionType.updateSubmenuType(submenuType)
                    )
                )
            }
        case MainMenuDetailsActionType.viewDidDisappear:
            self.submenuToDisplay = nil
        case MainMenuMiddlewareActionType.provideTabInfo(let info):
            if let info {
                self.currentTabInfo = info
                self.dispatchTabInfo(with: action.windowUUID, and: info)
            }
        case MainMenuMiddlewareActionType.updateSubmenuTypeTo(let submenuType):
            self.submenuToDisplay = submenuType

            store.dispatch(
                MainMenuAction(
                    windowUUID: action.windowUUID,
                    actionType: MainMenuDetailsActionType.updateSubmenuType(submenuType)
                )
            )
        case MainMenuActionType.mainMenuDidAppear:
            self.telemetry.mainMenuViewed()
        case MainMenuActionType.closeMenu:
            self.telemetry.mainMenuDismissed()
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
}
