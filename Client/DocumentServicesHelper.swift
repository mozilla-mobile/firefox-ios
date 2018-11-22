/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

class DocumentServicesHelper: TabEventHandler {
    private var tabObservers: TabObservers!
    private let prefs: Prefs

    init(_ prefs: Prefs) {
        self.prefs = prefs
        self.tabObservers = registerFor(
            .didLoadPageMetadata,
            queue: .main)
    }

    deinit {
        unregister(tabObservers)
    }

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        log.info("Here in DocumentServices")
    }
}
