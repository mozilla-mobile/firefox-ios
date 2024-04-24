// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

class ToolbarMiddleware {
    private let profile: Profile
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }

    lazy var toolbarProvider: Middleware<AppState> = { state, action in
        let uuid = action.windowUUID
        switch action {
        default:
            break
        }
    }
}
