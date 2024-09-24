// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

final class MainMenuMiddleware {
    private let logger: Logger
    private let telemetry = MainMenuTelemetry()

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    lazy var mainMenuProvider: Middleware<AppState> = { state, action in
        guard let action = action as? MainMenuAction else { return }

        switch action.actionType {
        case MainMenuActionType.closeMenu:
            self.telemetry.mainMenuDismissed()
        case MainMenuActionType.mainMenuDidAppear:
            self.telemetry.mainMenuViewed()
        case MainMenuActionType.viewDidLoad:
            store.dispatch(
                MainMenuAction(
                    windowUUID: action.windowUUID,
                    actionType: MainMenuMiddlewareActionType.requestTabInfo
                )
            )
        default:
            break
        }
    }
}
