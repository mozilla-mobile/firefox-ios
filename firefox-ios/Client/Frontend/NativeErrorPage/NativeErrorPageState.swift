// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

struct NativeErrorPageState: ScreenState {
    var windowUUID: WindowUUID
    var model: ErrorPageModel?

    var title: String { model?.title ?? "" }
    var description: String { model?.description ?? "" }
    var foxImage: String { model?.foxImageName ?? "" }
    var url: URL? { model?.url }
    var advancedSection: ErrorPageModel.AdvancedSectionConfig? { model?.advancedSection }
    var isRegularUI: Bool { model?.isRegularUI ?? false }

    init(appState: AppState, uuid: WindowUUID) {
        guard let nativeErrorPageState = appState.componentState(
            NativeErrorPageState.self,
            for: .nativeErrorPage,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: nativeErrorPageState.windowUUID,
            model: nativeErrorPageState.model
        )
    }

    init(
        windowUUID: WindowUUID,
        model: ErrorPageModel? = nil
    ) {
        self.windowUUID = windowUUID
        self.model = model
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
                model: model
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: NativeErrorPageState) -> NativeErrorPageState {
        return NativeErrorPageState(
            windowUUID: state.windowUUID,
            model: state.model
        )
    }
}
