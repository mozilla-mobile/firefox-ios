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
    var showGoBackButton: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let nativeErrorPageState = appState.screenState(
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
            showGoBackButton: nativeErrorPageState.showGoBackButton
        )
    }

    init(
        windowUUID: WindowUUID,
        title: String = "",
        description: String = "",
        foxImage: String = "",
        url: URL? = nil,
        advancedSection: ErrorPageModel.AdvancedSectionConfig? = nil,
        showGoBackButton: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.title = title
        self.description = description
        self.foxImage = foxImage
        self.url = url
        self.advancedSection = advancedSection
        self.showGoBackButton = showGoBackButton
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
                description: model.errorDescription,
                foxImage: model.foxImageName,
                url: model.url,
                advancedSection: model.advancedSection,
                showGoBackButton: model.showGoBackButton
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
            showGoBackButton: state.showGoBackButton
        )
    }
}
