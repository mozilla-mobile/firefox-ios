// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import Common

struct NativeErrorPageState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var title: String?
    var description: String?

    init(appState: AppState, uuid: WindowUUID) {
        guard let nativeErrorPageState = store.state.screenState(
            NativeErrorPageState.self,
            for: .nativeErrorPage,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: nativeErrorPageState.windowUUID,
            title: nativeErrorPageState.title,
            description: nativeErrorPageState.description
        )
    }

    init(
        windowUUID: WindowUUID,
        title: String? = nil,
        description: String? = nil
    ) {
        self.windowUUID = windowUUID
        self.title = title
        self.description = description
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case NativeErrorPageMiddlewareActionType.initialize:
            guard let action = action as? NativeErrorPageAction, let model = action.nativePageErrorModel else {
                return defaultState(from: state)
            }
            return NativeErrorPageState(
                windowUUID: state.windowUUID,
                title: model.errorTitle,
                description: model.errorDescription
            )
        default:
            return defaultState(from: state)
        }
    }
    
    static func defaultState(from state: NativeErrorPageState) -> NativeErrorPageState {
        return NativeErrorPageState(
            windowUUID: state.windowUUID,
            title: state.title,
            description: state.description
        )
    }
}
