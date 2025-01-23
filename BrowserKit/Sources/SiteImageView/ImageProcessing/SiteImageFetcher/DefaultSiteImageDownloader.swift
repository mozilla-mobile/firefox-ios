// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Kingfisher
import Common

class DefaultSiteImageDownloader: ImageDownloader, @unchecked Sendable, SiteImageDownloader {
    var timeoutDelay: Double { return 10 }
    var logger: Logger

    init(name: String = "default", logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        super.init(name: name)
    }
}
