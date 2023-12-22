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
    var isBottomSheetDisplayed: Bool
    var exposedToAdsEvent: Bool
    var notExposedToAdsEvent: Bool
    var areAdsSeen: Bool

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
            expandState: appState.fakespotState.expandState,
            isBottomSheetDisplayed: appState.fakespotState.isBottomSheetDisplayed,
            areAdsSeen: appState.fakespotState.areAdsSeen,
            exposedToAdsEvent: appState.fakespotState.exposedToAdsEvent,
            notExposedToAdsEvent: appState.fakespotState.notExposedToAdsEvent
        )
    }

    init() {
        self.init(
            isOpen: false,
            sidebarOpenForiPadLandscape: false,
            currentTabUUID: "",
            expandState: [:],
            isBottomSheetDisplayed: false,
            areAdsSeen: false,
            exposedToAdsEvent: false,
            notExposedToAdsEvent: false
        )
    }

    init(
        isOpen: Bool,
        sidebarOpenForiPadLandscape: Bool,
        currentTabUUID: String,
        expandState: [String: FakespotState.ExpandState] = [:],
        isBottomSheetDisplayed: Bool,
        areAdsSeen: Bool,
        exposedToAdsEvent: Bool,
        notExposedToAdsEvent: Bool
    ) {
        self.isOpen = isOpen
        self.sidebarOpenForiPadLandscape = sidebarOpenForiPadLandscape
        self.currentTabUUID = currentTabUUID
        self.expandState = expandState
        self.isBottomSheetDisplayed = isBottomSheetDisplayed
        self.areAdsSeen = areAdsSeen
        self.exposedToAdsEvent = exposedToAdsEvent
        self.notExposedToAdsEvent = notExposedToAdsEvent
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
            state.areAdsSeen = false
            state.exposedToAdsEvent = false
            state.notExposedToAdsEvent = false
            return state

        case FakespotAction.pressedShoppingButton:
            var state = state
            state.isOpen = !state.isOpen
            state.sidebarOpenForiPadLandscape = !state.isOpen
            if !state.isOpen {
                state.isBottomSheetDisplayed = false
            }
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
            state.isBottomSheetDisplayed = false
            return state

        case FakespotAction.setAppearanceTo(let isEnabled):
            var state = state
            state.isOpen = isEnabled
            state.isBottomSheetDisplayed = isEnabled
            return state

        case FakespotAction.bottomSheetDisplayed(let isDisplayed):
            var state = state
            state.isBottomSheetDisplayed = isDisplayed
            return state

        case FakespotAction.setAdsImpressionTo(let areAdsSeen):
            var state = state
            state.areAdsSeen = areAdsSeen
            return state

        case FakespotAction.setAdsExposureTo(let isExposedToAds):
            var state = state
            if isExposedToAds {
                state.exposedToAdsEvent = true
            } else {
                state.notExposedToAdsEvent = true
            }
            return state

        default:
            return state
        }
    }
}
