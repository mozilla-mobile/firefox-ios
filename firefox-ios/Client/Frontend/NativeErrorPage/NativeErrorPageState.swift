// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

struct NativeErrorPageState: ScreenState {
    var windowUUID: WindowUUID
    var title: String
    var description: String
    var foxImage: String
    var url: URL?
    var advancedSection: ErrorPageModel.AdvancedSectionConfig?
    var type: ErrorPageType

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
            title: nativeErrorPageState.title,
            description: nativeErrorPageState.description,
            foxImage: nativeErrorPageState.foxImage,
            url: nativeErrorPageState.url,
            advancedSection: nativeErrorPageState.advancedSection,
            type: nativeErrorPageState.type
        )
    }

    init(
        windowUUID: WindowUUID,
        title: String = "",
        description: String = "",
        foxImage: String = "",
        url: URL? = nil,
        advancedSection: ErrorPageModel.AdvancedSectionConfig? = nil,
        type: ErrorPageType = .generic
    ) {
        self.windowUUID = windowUUID
        self.title = title
        self.description = description
        self.foxImage = foxImage
        self.url = url
        self.advancedSection = advancedSection
        self.type = type
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, windowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
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
                description: model.errorDescription,
                foxImage: model.foxImageName,
                url: model.url,
                advancedSection: model.advancedSection,
                type: model.type
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: NativeErrorPageState) -> NativeErrorPageState {
        return NativeErrorPageState(
            windowUUID: state.windowUUID,
            title: state.title,
            description: state.description,
            foxImage: state.foxImage,
            url: state.url,
            advancedSection: state.advancedSection,
            type: state.type
        )
    }
}
