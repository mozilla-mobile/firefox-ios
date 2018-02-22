/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class TabEventHandlers {
    static func create(with prefs: Prefs) -> [TabEventHandler] {
        return [
            FaviconHandler(),
            UserActivityHandler(),
            MetadataParserHelper(),
            MediaImageLoader(prefs),
        ]
    }
}
