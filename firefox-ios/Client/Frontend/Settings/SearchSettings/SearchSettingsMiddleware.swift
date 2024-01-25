// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

class SearchSettingsMiddleware {
    private let profile: Profile
    init(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
    }

    lazy var searchSettingsManagerProvider: Middleware<AppState> = { state, action in
        switch action {
        case SearchSettingsAction.toggleSearchSuggestions(let toggleOn):
            self.profile.searchEngines.shouldShowSearchSuggestions = toggleOn
        default:
            break
        }
    }
}
