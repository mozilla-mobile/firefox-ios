// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TranslationsTabState: Equatable {
    var translationConfiguration: TranslationConfiguration?
}

protocol TranslationsTabStateStoring: AnyObject {
    func state(for tabUUID: TabUUID) -> TranslationsTabState
    func updateState(for tabUUID: TabUUID, _ update: (inout TranslationsTabState) -> Void)
    func removeState(for tabUUID: TabUUID)
}

/// Stores translation UI state keyed by `TabUUID` so the toolbar/menu can be re-synced with the
/// `WKWebView`'s translated DOM after a tab switch — the DOM survives across tab-tray visits, so
/// the icon state must too. Following the FXIOS-15001 pattern, this state lives off the `Tab`
/// to keep `Tab` focused on tab lifecycle, not feature UI state.
final class TranslationsTabStateStore: TranslationsTabStateStoring {
    private var states: [TabUUID: TranslationsTabState] = [:]

    func state(for tabUUID: TabUUID) -> TranslationsTabState {
        return states[tabUUID] ?? TranslationsTabState()
    }

    func updateState(for tabUUID: TabUUID, _ update: (inout TranslationsTabState) -> Void) {
        var state = states[tabUUID] ?? TranslationsTabState()
        update(&state)
        states[tabUUID] = state
    }

    func removeState(for tabUUID: TabUUID) {
        states.removeValue(forKey: tabUUID)
    }
}
