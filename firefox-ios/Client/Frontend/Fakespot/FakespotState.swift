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
    var tabAdsState: [String: AdsState]
    var wasSheetDisplayed: Bool

    struct AdsState: Equatable {
        var exposedToAdsEvent = false
        var notExposedToAdsEvent = false
        var areAdsSeen = false
    }

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
            wasSheetDisplayed: appState.fakespotState.wasSheetDisplayed,
            tabAdsState: appState.fakespotState.tabAdsState
        )
    }

    init() {
        self.init(
            isOpen: false,
            sidebarOpenForiPadLandscape: false,
            currentTabUUID: "",
            expandState: [:],
            wasSheetDisplayed: false,
            tabAdsState: [:]
        )
    }

    init(
        isOpen: Bool,
        sidebarOpenForiPadLandscape: Bool,
        currentTabUUID: String,
        expandState: [String: FakespotState.ExpandState] = [:],
        wasSheetDisplayed: Bool,
        tabAdsState: [String: AdsState] = [:]
    ) {
        self.isOpen = isOpen
        self.sidebarOpenForiPadLandscape = sidebarOpenForiPadLandscape
        self.currentTabUUID = currentTabUUID
        self.expandState = expandState
        self.wasSheetDisplayed = wasSheetDisplayed
        self.tabAdsState = tabAdsState
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
            // This condition checks for a page reload, 
            // signaling the start of a new browsing session,
            // and resets the 'areAdsSeen' flag to false.
            if state.currentTabUUID == tabUUID {
                state.tabAdsState[tabUUID]?.areAdsSeen = false
            } else if state.tabAdsState[tabUUID] == nil {
                state.tabAdsState[tabUUID] = AdsState()
            }
            state.currentTabUUID = tabUUID

            return state

        case FakespotAction.pressedShoppingButton:
            var state = state
            state.isOpen = !state.isOpen
            state.sidebarOpenForiPadLandscape = !state.isOpen
            if !state.isOpen {
                state.wasSheetDisplayed = false
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
            state.wasSheetDisplayed = false
            return state

        case FakespotAction.setAppearanceTo(let isEnabled):
            var state = state
            state.isOpen = isEnabled
            state.wasSheetDisplayed = isEnabled
            return state

        case FakespotAction.sheetDisplayed(let isDisplayed):
            var state = state
            state.wasSheetDisplayed = isDisplayed
            return state

        case FakespotAction.setAdsImpressionTo(let areAdsSeen, let tabUUID):
            guard let tabUUID else { return state }
            var state = state
            state.tabAdsState[tabUUID]?.areAdsSeen = areAdsSeen
            return state

        case FakespotAction.setAdsExposureTo(let isExposedToAds, let tabUUID):
            guard let tabUUID else { return state }
            var state = state
            if isExposedToAds {
                state.tabAdsState[tabUUID]?.exposedToAdsEvent = true
            } else {
                state.tabAdsState[tabUUID]?.notExposedToAdsEvent = true
            }
            return state

        default:
            return state
        }
    }
}
