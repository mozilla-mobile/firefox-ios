// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class GlobalTabEventHandlers {
    private static var globalHandlers: [TabEventHandler] = []

    /// Creates and configures the client's global TabEvent handlers. These handlers are created
    /// singularly for the entire app and respond to tab events across all windows. If the handlers
    /// have already been created this function does nothing.
    ///
    /// For anything that needs to react to tab events notifications (see `TabEventLabel`), the
    /// pattern is to implement a handler and specify which events to observe.
    static func configure(with profile: Profile) {
        guard globalHandlers.isEmpty else { return }
        globalHandlers = [
            UserActivityHandler(),
            MetadataParserHelper(),
            AccountSyncHandler(with: profile)
        ]
    }
}
