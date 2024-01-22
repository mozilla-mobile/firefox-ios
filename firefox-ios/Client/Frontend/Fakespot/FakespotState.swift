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
    var sendSurfaceDisplayedTelemetryEvent = true
    var windowUUID: WindowUUID

    struct TelemetryState: Equatable {
        var adEvents: [String: AdTelemetryState] = [:] // productId as key
    }

    struct AdTelemetryState: Equatable {
        var sendAdExposureEvent = true
        var sendAdsImpressionEvent = true
    }

    struct ExpandState: Equatable {
        var isSettingsExpanded = false
        var isReviewQualityExpanded = false
    }

    var isReviewQualityExpanded: Bool { expandState[currentTabUUID]?.isReviewQualityExpanded ?? false }
    var isSettingsExpanded: Bool { expandState[currentTabUUID]?.isSettingsExpanded ?? false }

    init(_ appState: BrowserViewControllerState) {
        self.init(
            windowUUID: appState.windowUUID,
            isOpen: appState.fakespotState.isOpen,
            sidebarOpenForiPadLandscape: appState.fakespotState.sidebarOpenForiPadLandscape,
            currentTabUUID: appState.fakespotState.currentTabUUID,
            expandState: appState.fakespotState.expandState,
            telemetryState: appState.fakespotState.telemetryState
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isOpen: false,
            sidebarOpenForiPadLandscape: false,
            currentTabUUID: "",
            expandState: [:],
            telemetryState: [:]
        )
    }

    init(
        windowUUID: WindowUUID,
        isOpen: Bool,
        sidebarOpenForiPadLandscape: Bool,
        currentTabUUID: String,
        expandState: [String: FakespotState.ExpandState] = [:],
        telemetryState: [String: TelemetryState] = [:]
    ) {
        self.windowUUID = windowUUID
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
            if state.telemetryState[tabUUID] == nil {
                state.telemetryState[tabUUID] = TelemetryState()
            }
            state.currentTabUUID = tabUUID

            return state

        case FakespotAction.tabDidReload(let tabUUID, let productId):
            guard state.currentTabUUID == tabUUID else { return state }

            var state = state
            state.telemetryState[tabUUID]?.adEvents[productId] = AdTelemetryState()
            return state

        case FakespotAction.pressedShoppingButton:
            var state = state
            state.isOpen = !state.isOpen
            state.sidebarOpenForiPadLandscape = state.isOpen
            if !state.isOpen {
                state.sendSurfaceDisplayedTelemetryEvent = true
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
            state.sendSurfaceDisplayedTelemetryEvent = true
            return state

        case FakespotAction.setAppearanceTo(let isEnabled):
            var state = state
            state.isOpen = isEnabled
            state.sendSurfaceDisplayedTelemetryEvent = !isEnabled
            return state

        case FakespotAction.surfaceDisplayedEventSend:
            var state = state
            state.sendSurfaceDisplayedTelemetryEvent = false
            return state

        case FakespotAction.adsImpressionEventSendFor(let productId):
            var state = state
            if state.telemetryState[state.currentTabUUID]?.adEvents[productId] == nil {
                state.telemetryState[state.currentTabUUID]?.adEvents[productId] = AdTelemetryState()
            }
            state.telemetryState[state.currentTabUUID]?.adEvents[productId]?.sendAdsImpressionEvent = false
            return state

        case FakespotAction.adsExposureEventSendFor(let productId):
            var state = state
            if state.telemetryState[state.currentTabUUID]?.adEvents[productId] == nil {
                state.telemetryState[state.currentTabUUID]?.adEvents[productId] = AdTelemetryState()
            }
            state.telemetryState[state.currentTabUUID]?.adEvents[productId]?.sendAdExposureEvent = false
            return state

        default:
            return state
        }
    }
}
