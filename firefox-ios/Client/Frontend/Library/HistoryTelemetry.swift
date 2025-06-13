// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct HistoryTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Recorded when the app has automatically migrated a user's history after updating from version 110. Migration was
    /// necessary due to an application services change. This was a change back in 2022.
    /// Once usage of this event falls below an acceptable threshold, we can remove the associated migration code and this
    /// event.
    func attemptedApplicationServicesMigration() {
        gleanWrapper.recordEvent(for: GleanMetrics.HistoryMigration2022.migrationAttempted)
    }
}
