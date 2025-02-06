// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TimeBasedRefreshingRule: RefreshingRule {

    let interval: TimeInterval
    let timestampProvider: TimestampProvider

    init(interval: TimeInterval, timestampProvider: TimestampProvider = Date()) {
        self.interval = interval
        self.timestampProvider = timestampProvider
    }

    var shouldRefresh: Bool {
        return timestampProvider.currentTimestamp - Unleash.model.updated.timeIntervalSince1970 > interval
    }
}
