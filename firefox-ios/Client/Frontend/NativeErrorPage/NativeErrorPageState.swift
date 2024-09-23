// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import Common

struct NativeErrorPageState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var shouldReload: Bool
//    var showProceedToURL: Bool
//    var showLearnMore: Bool
//    var showCertificate: Bool
//    var shouldGoBack: Bool

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
            shouldReload: nativeErrorPageState.shouldReload
//            showProceedToURL: nativeErrorPageState.showProceedToURL,
//            showLearnMore: nativeErrorPageState.showLearnMore,
//            showCertificate: nativeErrorPageState.showCertificate,
//            shouldGoBack: nativeErrorPageState.shouldGoBack
        )
    }

    init(
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            shouldReload: false
//            showProceedToURL: false,
//            showLearnMore: false,
//            showCertificate: false,
//            shouldGoBack: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldReload: Bool
//        showProceedToURL: Bool,
//        showLearnMore: Bool,
//        showCertificate: Bool,
//        shouldGoBack: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldReload = shouldReload
//        self.showProceedToURL = showProceedToURL
//        self.showLearnMore = showLearnMore
//        self.showCertificate = showCertificate
//        self.shouldGoBack = shouldGoBack
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case NativeErrorPageActionType.reload:
            return NativeErrorPageState(
                windowUUID: state.windowUUID,
                shouldReload: true
//                showProceedToURL: false,
//                showLearnMore: false,
//                showCertificate: false,
//                shouldGoBack: false
            )
//        case NativeErrorPageActionType.goBack:
//            return NativeErrorPageState(
//                windowUUID: state.windowUUID,
//                shouldReload: false,
//                showProceedToURL: false,
//                showLearnMore: false,
//                showCertificate: false,
//                shouldGoBack: true
//            )
//        case NativeErrorPageActionType.tapAdvanced:
//            return NativeErrorPageState(
//                windowUUID: state.windowUUID,
//                shouldReload: false,
//                showProceedToURL: true,
//                showLearnMore: false,
//                showCertificate: false,
//                shouldGoBack: false
//            )
//        case NativeErrorPageActionType.learMore:
//            return NativeErrorPageState(
//                windowUUID: state.windowUUID,
//                shouldReload: false,
//                showProceedToURL: false,
//                showLearnMore: true,
//                showCertificate: false,
//                shouldGoBack: false
//            )
//        case NativeErrorPageActionType.viewCertificate:
//            return NativeErrorPageState(
//                windowUUID: state.windowUUID,
//                shouldReload: false,
//                showProceedToURL: false,
//                showLearnMore: false,
//                showCertificate: true,
//                shouldGoBack: false
//            )
        default:
            return NativeErrorPageState(
                windowUUID: state.windowUUID,
                shouldReload: false
//                showProceedToURL: false,
//                showLearnMore: false,
//                showCertificate: false,
//                shouldGoBack: false
            )
        }
    }
}
