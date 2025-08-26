// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

final class ShortcutsLibraryMiddleware {
    private let shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry

    init(shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry = ShortcutsLibraryTelemetry()) {
        self.shortcutsLibraryTelemetry = shortcutsLibraryTelemetry
    }

    lazy var shortcutsLibraryProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case ShortcutsLibraryActionType.tapOnBackBarButton:
            self.shortcutsLibraryTelemetry.sendShortcutsLibraryClosedEvent()
        case ShortcutsLibraryActionType.tapOnShortcutCell:
            self.shortcutsLibraryTelemetry.sendShortcutTappedEvent()
        case ShortcutsLibraryActionType.viewDidAppear:
            self.shortcutsLibraryTelemetry.sendShortcutsLibraryViewedEvent()
        default:
            break
        }
    }
}
