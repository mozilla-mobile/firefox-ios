// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Sentry

// MARK: - SentryWrapper
protocol SentryWrapper {
    func setup(sendUsageData: Bool)
    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: Any]?)
}

struct DefaultSentryWrapper: SentryWrapper {
    func setup(sendUsageData: Bool) {
        // TODO: Laurie
    }

    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: Any]?) {
        // TODO: Laurie
    }
}
