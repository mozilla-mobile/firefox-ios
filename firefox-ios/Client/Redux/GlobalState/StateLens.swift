// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// A Lens allows our UI layers (e.g. a `UIViewController`) to subscribe to multiple pieces of Redux state
/// (e.g. `ToolbarState` and `TranslationsState`). This is helpful because it is unnecessary to duplicate state across
/// multiple Redux `State`s and update that duplicate same state in multiple `Reducer`s.
///
/// A Lens builds itself directly from the full `AppState`. This allows the Lens to combine fields from multiple component
/// states without any state needing to know about other states.
///
/// Any property that can be derived solely from `AppState` can be moved to a `Lens` to simplify work in our reducers.
@MainActor
protocol StateLens: Equatable {
    init(appState: AppState, uuid: WindowUUID)
}
