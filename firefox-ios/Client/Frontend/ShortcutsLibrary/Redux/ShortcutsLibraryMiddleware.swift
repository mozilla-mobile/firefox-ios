// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

final class ShortcutsLibraryMiddleware {
    private let logger: Logger
    private let shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry

    init(logger: Logger = DefaultLogger.shared,
         shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry = ShortcutsLibraryTelemetry()) {
        self.logger = logger
        self.shortcutsLibraryTelemetry = shortcutsLibraryTelemetry
    }

    lazy var shortcutsLibraryProvider: Middleware<AppState> = { state, action in
        // TODO: FXIOS-12557 We assume that we are isolated to the Main Actor
        // because we dispatch to the main thread in the store. We will want
        // to also isolate that to the @MainActor to remove this.
        guard Thread.isMainThread else {
            self.logger.log(
                "Shortcuts Library Middleware is not being called from the main thread!",
                level: .fatal,
                category: .shortcutsLibrary
            )
            return
        }

        MainActor.assumeIsolated {
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
    }

    @MainActor
    private func handleViewDidAppearAction(state: AppState, action: Action) {
        guard let shortcutsLibraryState = state.screenState(ShortcutsLibraryState.self,
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
