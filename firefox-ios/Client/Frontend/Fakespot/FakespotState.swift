// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpen: Bool
    var sidebarOpenForiPadLandscape: Bool
    var currentTabUUID: String
    var expandState: [TabUUID: ExpandState]
    var telemetryState: [TabUUID: TelemetryState]
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
        var isHighlightsSectionExpanded = false
    }

    var isReviewQualityExpanded: Bool { expandState[currentTabUUID]?.isReviewQualityExpanded ?? false }
    var isSettingsExpanded: Bool { expandState[currentTabUUID]?.isSettingsExpanded ?? false }
    var isHighlightsSectionExpanded: Bool { expandState[currentTabUUID]?.isHighlightsSectionExpanded ?? false }

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
        currentTabUUID: TabUUID,
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
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
            let action = action as? FakespotAction else { return state }

        switch action.actionType {
        case FakespotActionType.settingsStateDidChange:
            return handleSettings(action: action, state: state)

        case FakespotActionType.reviewQualityDidChange:
            return handleReviewQuality(action: action, state: state)

        case FakespotActionType.highlightsDidChange:
            return handleHighlights(action: action, state: state)

        case FakespotActionType.tabDidChange:
            return handleTabDidChange(action: action, state: state)

        case FakespotActionType.tabDidReload:
            return handleTabDidReload(action: action, state: state)

        case FakespotActionType.pressedShoppingButton:
            return handlePressedShoppingButton(state: state)

        case FakespotActionType.show:
            return handleShow(state: state)

        case FakespotActionType.dismiss:
            return handleDismiss(state: state)

        case FakespotActionType.setAppearanceTo:
            return handleAppearance(action: action, state: state)

        case FakespotActionType.surfaceDisplayedEventSend:
            return handleSurfaceDisplayedEvent(state: state)

        case FakespotActionType.adsImpressionEventSendFor:
            return handleAdsImpression(action: action, state: state)

        case FakespotActionType.adsExposureEventSendFor:
            return handleAdsExposure(action: action, state: state)

        default:
            return state
        }
    }

    private static func handleSettings(action: FakespotAction, state: FakespotState) -> FakespotState {
        let isExpanded = action.isExpanded ?? state.isSettingsExpanded
        var state = state
        state.expandState[state.currentTabUUID, default: ExpandState()].isSettingsExpanded = isExpanded
        return state
    }

    private static func handleReviewQuality(action: FakespotAction, state: FakespotState) -> FakespotState {
        let isExpanded = action.isExpanded ?? state.isReviewQualityExpanded
        var state = state
        state.expandState[state.currentTabUUID, default: ExpandState()].isReviewQualityExpanded = isExpanded
        return state
    }

    private static func handleHighlights(action: FakespotAction, state: FakespotState) -> FakespotState {
        let isExpanded = action.isExpanded ?? state.isHighlightsSectionExpanded
        var state = state
        state.expandState[state.currentTabUUID, default: ExpandState()].isHighlightsSectionExpanded = isExpanded
        return state
    }

    private static func handleTabDidChange(action: FakespotAction, state: FakespotState) -> FakespotState {
        guard let tabUUID = action.tabUUID else { return state }
        var state = state
        if state.telemetryState[tabUUID] == nil {
            state.telemetryState[tabUUID] = TelemetryState()
        }
        state.currentTabUUID = tabUUID

        return state
    }

    private static func handleTabDidReload(action: FakespotAction, state: FakespotState) -> FakespotState {
        guard let tabUUID = action.tabUUID,
                state.currentTabUUID == tabUUID,
                let productId = action.productId
        else { return state }

        var state = state
        state.telemetryState[tabUUID]?.adEvents[productId] = AdTelemetryState()
        return state
    }

    private static func handlePressedShoppingButton(state: FakespotState) -> FakespotState {
        var state = state
        state.isOpen = !state.isOpen
        state.sidebarOpenForiPadLandscape = state.isOpen
        if !state.isOpen {
            state.sendSurfaceDisplayedTelemetryEvent = true
        }
        return state
    }

    private static func handleShow(state: FakespotState) -> FakespotState {
        var state = state
        state.isOpen = true
        state.sidebarOpenForiPadLandscape = true
        return state
    }

    private static func handleDismiss(state: FakespotState) -> FakespotState {
        var state = state
        state.isOpen = false
        state.sidebarOpenForiPadLandscape = false
        state.sendSurfaceDisplayedTelemetryEvent = true
        return state
    }

    private static func handleAppearance(action: FakespotAction, state: FakespotState) -> FakespotState {
        let isEnabled = action.isOpen ?? state.isOpen
        var state = state
        state.isOpen = isEnabled
        state.sendSurfaceDisplayedTelemetryEvent = !isEnabled
        return state
    }

    private static func handleSurfaceDisplayedEvent(state: FakespotState) -> FakespotState {
        var state = state
        state.sendSurfaceDisplayedTelemetryEvent = false
        return state
    }

    private static func handleAdsImpression(action: FakespotAction, state: FakespotState) -> FakespotState {
        guard let productId = action.productId else { return state }
        var state = state
        if state.telemetryState[state.currentTabUUID]?.adEvents[productId] == nil {
            state.telemetryState[state.currentTabUUID]?.adEvents[productId] = AdTelemetryState()
        }
        state.telemetryState[state.currentTabUUID]?.adEvents[productId]?.sendAdsImpressionEvent = false
        return state
    }

    private static func handleAdsExposure(action: FakespotAction, state: FakespotState) -> FakespotState {
        guard let productId = action.productId else { return state }
        var state = state
        if state.telemetryState[state.currentTabUUID]?.adEvents[productId] == nil {
            state.telemetryState[state.currentTabUUID]?.adEvents[productId] = AdTelemetryState()
        }
        state.telemetryState[state.currentTabUUID]?.adEvents[productId]?.sendAdExposureEvent = false
        return state
    }
}
