// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux

@CopyWithUpdates
struct ShortcutsLibraryState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    let shortcuts: [TopSiteConfiguration]
    let shouldRecordImpressionTelemetry: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let shortcutsLibraryState = appState.componentState(
            ShortcutsLibraryState.self,
            for: .shortcutsLibrary,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self = shortcutsLibraryState.copyWithUpdates()
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            shortcuts: [],
            shouldRecordImpressionTelemetry: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shortcuts: [TopSiteConfiguration],
        shouldRecordImpressionTelemetry: Bool
    ) {
        self.windowUUID = windowUUID
        self.shortcuts = shortcuts
        self.shouldRecordImpressionTelemetry = shouldRecordImpressionTelemetry
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ShortcutsLibraryActionType.initialize:
            return handleInitializeAction(state: state)
        case ShortcutsLibraryMiddlewareActionType.impressionTelemetryRecorded:
            return handleImpressionTelemetryRecordedAction(state: state)
        case TopSitesMiddlewareActionType.retrievedUpdatedSites:
            return handleRetrievedUpdatedSitesAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(state: Self) -> ShortcutsLibraryState {
        return state.copyWithUpdates(
            shouldRecordImpressionTelemetry: true
        )
    }

    private static func handleImpressionTelemetryRecordedAction(state: Self) -> ShortcutsLibraryState {
        return state.copyWithUpdates(
            shouldRecordImpressionTelemetry: false
        )
    }

    private static func handleRetrievedUpdatedSitesAction(action: Action, state: Self) -> ShortcutsLibraryState {
        guard let topSitesAction = action as? TopSitesAction,
              let sites = topSitesAction.topSites
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            shortcuts: sites
        )
    }

    static func defaultState(from state: ShortcutsLibraryState) -> ShortcutsLibraryState {
        return state.copyWithUpdates()
    }
}
