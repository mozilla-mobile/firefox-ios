// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpenOnProductPage: Bool
    var isSettingsExpanded: Bool
    var isReviewQualityExpanded: Bool

    init(_ appState: AppState) {
        guard let fakespotState = store.state.screenState(FakespotState.self, for: .fakespot) else {
            self.init()
            return
        }

        self.init(
            isOpenOnProductPage: fakespotState.isOpenOnProductPage,
            isSettingsExpanded: fakespotState.isSettingsExpanded,
            isReviewQualityExpanded: fakespotState.isReviewQualityExpanded
        )
    }

    init() {
        self.init(
            isOpenOnProductPage: false,
            isSettingsExpanded: false,
            isReviewQualityExpanded: false
        )
    }

    init(isOpenOnProductPage: Bool, isSettingsExpanded: Bool, isReviewQualityExpanded: Bool) {
        self.isOpenOnProductPage = isOpenOnProductPage
        self.isSettingsExpanded = isSettingsExpanded
        self.isReviewQualityExpanded = isReviewQualityExpanded
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FakespotAction.toggleAppearance(let isEnabled):
            return FakespotState(
                isOpenOnProductPage: isEnabled,
                isSettingsExpanded: state.isSettingsExpanded,
                isReviewQualityExpanded: state.isReviewQualityExpanded
            )
        case FakespotAction.settingsStateDidChange:
            var state = state
            state.isSettingsExpanded.toggle()
            return state
        case FakespotAction.reviewQualityDidChange:
            var state = state
            state.isReviewQualityExpanded.toggle()
            return state
        case FakespotAction.urlDidChange:
            var state = state
            state.isReviewQualityExpanded = false
            state.isReviewQualityExpanded = false
            return state
        default:
            return state
        }
    }

    static func == (lhs: FakespotState, rhs: FakespotState) -> Bool {
        lhs.isOpenOnProductPage == rhs.isOpenOnProductPage
        && lhs.isSettingsExpanded == rhs.isSettingsExpanded
        && lhs.isReviewQualityExpanded == rhs.isReviewQualityExpanded
    }
}
