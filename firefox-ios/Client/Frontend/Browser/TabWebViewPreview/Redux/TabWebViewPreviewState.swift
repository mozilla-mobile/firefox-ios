// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TabWebViewPreviewState: ScreenState, Equatable {
    let windowUUID: WindowUUID = .unavailable
    let addressBarPosition: SearchBarPosition

    // MARK: - Inits
    init() { addressBarPosition = .top }

    init(addressBarPosition: SearchBarPosition) {
        self.addressBarPosition = addressBarPosition
    }

    init(appState: AppState) {
        guard let state = store.state.screenState(
            Self.self,
            for: .tabWebViewPreview,
            window: .unavailable
        )
        else {
            self.init()
            return
        }
        self.init(addressBarPosition: state.addressBarPosition)
    }

    static func defaultState(from state: Self) -> Self {
        return Self(addressBarPosition: state.addressBarPosition)
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action.actionType {
        case TabWebViewPreviewActionType.changeAddressBarPosition:
            guard let addressBarPosition = (action as? TabWebViewPreviewAction)?.addressBarPosition
            else {
                return defaultState(from: state)
            }
            return Self(addressBarPosition: addressBarPosition)
        default: return defaultState(from: state)
        }
    }
}
