// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpen: Bool
    var sidebarOpenForiPadLandscape: Bool
    var currentTabUUID: String
    var expandState: [String: ExpandState] // tabUUID as key
    var telemetryState: [String: TelemetryState] // tabUUID as key

    struct TelemetryState: Equatable {
        var sheetDisplayedEvent = false
        var adEvents: [String: AdTelemetryState] = [:] // productId as key
    }

    struct AdTelemetryState: Equatable {
        var adExposureEvent = false
        var adsImpressionEvent = false
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
            telemetryState: appState.fakespotState.telemetryState
        )
    }

    init() {
        self.init(
            isOpen: false,
            sidebarOpenForiPadLandscape: false,
            currentTabUUID: "",
            expandState: [:],
            telemetryState: [:]
        )
    }

    init(
        isOpen: Bool,
        sidebarOpenForiPadLandscape: Bool,
        currentTabUUID: String,
        expandState: [String: FakespotState.ExpandState] = [:],
        telemetryState: [String: TelemetryState] = [:]
    ) {
        self.isOpen = isOpen
        self.sidebarOpenForiPadLandscape = sidebarOpenForiPadLandscape
        self.currentTabUUID = currentTabUUID
        self.expandState = expandState
        self.telemetryState = telemetryState
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
                state.telemetryState[tabUUID]?.adEvents = [:]
            } else if state.telemetryState[tabUUID] == nil {
                state.telemetryState[tabUUID] = TelemetryState()
            }
            state.currentTabUUID = tabUUID

            return state

        case FakespotAction.pressedShoppingButton:
            var state = state
            state.isOpen = !state.isOpen
            state.sidebarOpenForiPadLandscape = !state.isOpen
            if !state.isOpen {
                state.telemetryState[state.currentTabUUID]?.sheetDisplayedEvent = false
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
            state.telemetryState[state.currentTabUUID]?.sheetDisplayedEvent = false
            return state

        case FakespotAction.setAppearanceTo(let isEnabled):
            var state = state
            state.isOpen = isEnabled
            state.telemetryState[state.currentTabUUID]?.sheetDisplayedEvent = isEnabled
            return state

        case FakespotAction.sheetDisplayedEventSend:
            var state = state
            state.telemetryState[state.currentTabUUID]?.sheetDisplayedEvent = true
            return state

        case FakespotAction.adsImpressionEventSendFor(let productId):
            var state = state
            state.telemetryState[state.currentTabUUID]?.adEvents[productId]?.adsImpressionEvent = true
            return state

        case FakespotAction.adsExposureEventSendFor(let productId):
            var state = state
            state.telemetryState[state.currentTabUUID]?.adEvents[productId]?.adExposureEvent = true
            return state

        default:
            return state
        }
    }
}
