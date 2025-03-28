// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct HistoryDeletionUtilityTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func clearedHistory(_ dateOption: HistoryDeletionUtilityDateOptions) {
        let timeframeExtra = GleanMetrics.LibraryHistoryPanel.ClearedHistoryExtra(timeframe: dateOption.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.LibraryHistoryPanel.clearedHistory, extras: timeframeExtra)
    }
}
