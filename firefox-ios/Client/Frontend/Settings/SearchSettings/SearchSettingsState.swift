// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared

struct SearchSettingsState: ScreenState, Equatable {
    var navigationItemTitle: String
    var isTableViewEditing: Bool
    var allowTableViewSelectionDuringEditing: Bool

    init(_ appState: AppState) {
        self.init()
    }

    init() {
        self.init(navigationItemTitle: .Settings.Search.Title,
                  isTableViewEditing: true,
                  allowTableViewSelectionDuringEditing: true)
    }

    init(navigationItemTitle: String,
         isTableViewEditing: Bool,
         allowTableViewSelectionDuringEditing: Bool) {
        self.navigationItemTitle = navigationItemTitle
        self.isTableViewEditing = isTableViewEditing
        self.allowTableViewSelectionDuringEditing = allowTableViewSelectionDuringEditing
    }

    static let reducer: Reducer<Self> = { state, action in
        return state
    }
}
