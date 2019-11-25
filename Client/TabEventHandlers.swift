/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class TabEventHandlers {
    static func create(with prefs: Prefs) -> [TabEventHandler] {
        var handlers: [TabEventHandler] = [
            FaviconHandler(),
            UserActivityHandler(),
            MetadataParserHelper(),
            MediaImageLoader(prefs),
        ]

        if AppConstants.MOZ_DOCUMENT_SERVICES {
            handlers = handlers + [
                DocumentServicesHelper(),
                TranslationToastHandler(prefs),
            ]
        }

        return handlers
    }
}
