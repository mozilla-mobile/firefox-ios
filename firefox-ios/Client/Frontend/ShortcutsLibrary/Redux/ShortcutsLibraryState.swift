// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ShortcutsLibraryState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    let shortcuts: [TopSiteConfiguration]
    let shouldRecordImpressionTelemetry: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let shortcutsLibraryState = appState.screenState(
            ShortcutsLibraryState.self,
            for: .shortcutsLibrary,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: shortcutsLibraryState.windowUUID,
            shortcuts: shortcutsLibraryState.shortcuts,
            shouldRecordImpressionTelemetry: shortcutsLibraryState.shouldRecordImpressionTelemetry
        )
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
        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            shortcuts: state.shortcuts,
            shouldRecordImpressionTelemetry: true
        )
    }

    private static func handleImpressionTelemetryRecordedAction(state: Self) -> ShortcutsLibraryState {
        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            shortcuts: state.shortcuts,
            shouldRecordImpressionTelemetry: false
        )
    }

    private static func handleRetrievedUpdatedSitesAction(action: Action, state: Self) -> ShortcutsLibraryState {
        guard let topSitesAction = action as? TopSitesAction,
              let sites = topSitesAction.topSites
        else {
            return defaultState(from: state)
        }

        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            shortcuts: sites,
            shouldRecordImpressionTelemetry: state.shouldRecordImpressionTelemetry
        )
    }

    static func defaultState(from state: ShortcutsLibraryState) -> ShortcutsLibraryState {
        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            shortcuts: state.shortcuts,
            shouldRecordImpressionTelemetry: state.shouldRecordImpressionTelemetry
        )
    }
}
