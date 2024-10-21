// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

final class PocketMiddleware {
    private let pocketManager: PocketManagerProvider
    init(pocketManager: PocketManagerProvider = AppContainer.shared.resolve()) {
        self.pocketManager = pocketManager
    }

    lazy var pocketSectionProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
            PocketActionType.enteredForeground:
            self.getPocketDataAndUpdateState(for: action)
        default:
            break
        }
    }

    private func getPocketDataAndUpdateState(for action: Action) {
        Task {
            let pocketStories = await pocketManager.getPocketItems()
            store.dispatch(
                PocketAction(
                    pocketStories: pocketStories,
                    windowUUID: action.windowUUID,
                    actionType: PocketMiddlewareActionType.retrievedUpdatedStories
                )
            )
        }
    }
}
