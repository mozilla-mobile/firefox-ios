// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

@MainActor
final class ShortcutsLibraryMiddleware {
    private let logger: Logger
    private let shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry

    init(logger: Logger = DefaultLogger.shared,
         shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry = ShortcutsLibraryTelemetry()) {
        self.logger = logger
        self.shortcutsLibraryTelemetry = shortcutsLibraryTelemetry
    }

    lazy var shortcutsLibraryProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareMethod<AppState> = { [self] state, action, windowUUID in
        // Does not test any modern actions
    }

    lazy var legacyProvider: LegacyMiddlewareMethod<AppState> = { [self] state, action in
        switch action.actionType {
        case ShortcutsLibraryActionType.tapOnShortcutCell:
            self.shortcutsLibraryTelemetry.sendShortcutTappedEvent()
        case ShortcutsLibraryActionType.viewDidAppear:
            self.handleViewDidAppearAction(state: state, action: action)
        case ShortcutsLibraryActionType.viewDidDisappear:
            self.shortcutsLibraryTelemetry.sendShortcutsLibraryClosedEvent()
        default:
            break
        }
    }

    @MainActor
    private func handleViewDidAppearAction(state: AppState, action: Action) {
        guard let shortcutsLibraryState = state.componentState(ShortcutsLibraryState.self,
                                                               for: .shortcutsLibrary,
                                                               window: action.windowUUID) else { return }
        if shortcutsLibraryState.shouldRecordImpressionTelemetry {
            self.shortcutsLibraryTelemetry.sendShortcutsLibraryViewedEvent()
            store.dispatch(
                ShortcutsLibraryAction(
                    windowUUID: action.windowUUID,
                    actionType: ShortcutsLibraryMiddlewareActionType.impressionTelemetryRecorded
                )
            )
        }
    }
}
