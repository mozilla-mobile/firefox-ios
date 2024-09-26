// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import Common

struct NativeErrorPageState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var showAdvanced: Bool
    var showLearnMore: Bool
    var showCertificate: Bool

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
            showAdvanced: nativeErrorPageState.showAdvanced,
            showLearnMore: nativeErrorPageState.showLearnMore,
            showCertificate: nativeErrorPageState.showCertificate
        )
    }

    init(
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            showAdvanced: false,
            showLearnMore: false,
            showCertificate: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        showAdvanced: Bool,
        showLearnMore: Bool,
        showCertificate: Bool
    ) {
        self.windowUUID = windowUUID
        self.showAdvanced = showAdvanced
        self.showLearnMore = showLearnMore
        self.showCertificate = showCertificate
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case NativeErrorPageActionType.tapAdvanced:
            return NativeErrorPageState(
                windowUUID: state.windowUUID,
                showAdvanced: true,
                showLearnMore: false,
                showCertificate: false
            )
        case NativeErrorPageActionType.learMore:
            return NativeErrorPageState(
                windowUUID: state.windowUUID,
                showAdvanced: false,
                showLearnMore: true,
                showCertificate: false
            )
        case NativeErrorPageActionType.viewCertificate:
            return NativeErrorPageState(
                windowUUID: state.windowUUID,
                showAdvanced: false,
                showLearnMore: false,
                showCertificate: true
            )
        default:
            return NativeErrorPageState(
                windowUUID: state.windowUUID,
                showAdvanced: false,
                showLearnMore: false,
                showCertificate: false
            )
        }
    }
}
