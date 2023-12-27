// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpen: Bool
    var sidebarOpenForiPadLandscape: Bool
    var currentTabUUID: String
    var expandState: [String: ExpandState]

    struct ExpandState: Equatable {
        var isSettingsExpanded = false
        var isReviewQualityExpanded = false
    }

    var isReviewQualityExpanded: Bool { expandState[currentTabUUID]?.isReviewQualityExpanded ?? false }
    var isSettingsExpanded: Bool { expandState[currentTabUUID]?.isSettingsExpanded ?? false }

    init(_ appState: BrowserViewControllerState) {
        self.init(
            isOpen: appState.fakespotState.isOpen,
            sidebarOpenForiPadLandscape: appState.fakespotState.sidebarOpenForiPadLandscape,
            currentTabUUID: appState.fakespotState.currentTabUUID,
            expandState: appState.fakespotState.expandState
        )
    }

    init() {
        self.init(isOpen: false, sidebarOpenForiPadLandscape: false, currentTabUUID: "", expandState: [:])
    }

    init(
        isOpen: Bool,
        sidebarOpenForiPadLandscape: Bool,
        currentTabUUID: String,
        expandState: [String: FakespotState.ExpandState] = [:]
    ) {
        self.isOpen = isOpen
        self.sidebarOpenForiPadLandscape = sidebarOpenForiPadLandscape
        self.currentTabUUID = currentTabUUID
        self.expandState = expandState
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FakespotAction.settingsStateDidChange:
            var state = state
            state.expandState[state.currentTabUUID, default: ExpandState()].isSettingsExpanded.toggle()
            return state

        case FakespotAction.reviewQualityDidChange:
            var state = state
            state.expandState[state.currentTabUUID, default: ExpandState()].isReviewQualityExpanded.toggle()
            return state

        case FakespotAction.tabDidChange(let tabUUID):
            var state = state
            state.currentTabUUID = tabUUID
            return state

        case FakespotAction.pressedShoppingButton:
            var state = state
            state.isOpen = !state.isOpen
            state.sidebarOpenForiPadLandscape = !state.isOpen
            return state

        case FakespotAction.show:
            var state = state
            state.isOpen = true
            state.sidebarOpenForiPadLandscape = true
            return state

        case FakespotAction.dismiss:
            var state = state
            state.isOpen = false
            state.sidebarOpenForiPadLandscape = false
            return state

        case FakespotAction.setAppearanceTo(let isEnabled):
            var state = state
            state.isOpen = isEnabled
            return state

        default:
            return state
        }
    }
}
