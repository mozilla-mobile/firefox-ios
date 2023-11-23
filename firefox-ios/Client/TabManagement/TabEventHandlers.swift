// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class TabEventHandlers {
    /// Create handlers that observe specified tab events.
    ///
    /// For anything that needs to react to tab events notifications (see `TabEventLabel`), the
    /// pattern is to implement a handler and specify which events to observe.
    static func create(with profile: Profile) -> [TabEventHandler] {
        let handlers: [TabEventHandler] = [
            UserActivityHandler(),
            MetadataParserHelper(),
            AccountSyncHandler(with: profile)
        ]

        return handlers
    }
}
