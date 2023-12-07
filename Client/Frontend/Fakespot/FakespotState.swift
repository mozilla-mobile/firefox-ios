// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpen: Bool
    var sidebarOpenForiPadLandscape: Bool
    var isSettingsExpanded: Bool
    var isReviewQualityExpanded: Bool

    init(_ appState: BrowserViewControllerState) {
        self.init(
            isOpen: appState.fakespotState.isOpen,
            sidebarOpenForiPadLandscape: appState.fakespotState.sidebarOpenForiPadLandscape,
            isSettingsExpanded: appState.fakespotState.isSettingsExpanded,
            isReviewQualityExpanded: appState.fakespotState.isReviewQualityExpanded
        )
    }

    init() {
        self.init(isOpen: false, sidebarOpenForiPadLandscape: false, isSettingsExpanded: false, isReviewQualityExpanded: false)
    }

    init(isOpen: Bool, sidebarOpenForiPadLandscape: Bool, isSettingsExpanded: Bool, isReviewQualityExpanded: Bool) {
        self.isOpen = isOpen
        self.sidebarOpenForiPadLandscape = sidebarOpenForiPadLandscape
        self.isSettingsExpanded = isSettingsExpanded
        self.isReviewQualityExpanded = isReviewQualityExpanded
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FakespotAction.settingsStateDidChange:
            var state = state
            state.isSettingsExpanded.toggle()
            return state
        case FakespotAction.reviewQualityDidChange:
            var state = state
            state.isReviewQualityExpanded.toggle()
            return state
        case FakespotAction.urlDidChange:
            return FakespotState(
                isOpen: state.isOpen,
                sidebarOpenForiPadLandscape: state.sidebarOpenForiPadLandscape,
                isSettingsExpanded: false,
                isReviewQualityExpanded: false
            )
        case FakespotAction.pressedShoppingButton:
            return FakespotState(
                isOpen: !state.isOpen,
                sidebarOpenForiPadLandscape: !state.isOpen,
                isSettingsExpanded: state.isSettingsExpanded,
                isReviewQualityExpanded: state.isReviewQualityExpanded
            )
        case FakespotAction.show:
            return FakespotState(
                isOpen: true,
                sidebarOpenForiPadLandscape: true,
                isSettingsExpanded: state.isSettingsExpanded,
                isReviewQualityExpanded: state.isReviewQualityExpanded
            )
        case FakespotAction.dismiss:
            return FakespotState(
                isOpen: false,
                sidebarOpenForiPadLandscape: false,
                isSettingsExpanded: state.isSettingsExpanded,
                isReviewQualityExpanded: state.isReviewQualityExpanded
            )
        case FakespotAction.setAppearanceTo(let isEnabled):
            return FakespotState(
                isOpen: isEnabled,
                sidebarOpenForiPadLandscape: state.sidebarOpenForiPadLandscape,
                isSettingsExpanded: state.isSettingsExpanded,
                isReviewQualityExpanded: state.isReviewQualityExpanded
            )
        default:
            return state
        }
    }
}
