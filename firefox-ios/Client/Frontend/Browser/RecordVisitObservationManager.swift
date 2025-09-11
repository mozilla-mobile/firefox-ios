// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import WebKit

// Handles recording visit to website that will be used to list History
class RecordVisitObservationManager {
    private var historyHandler: HistoryHandler
    nonisolated let logger: Logger
    var lastObservationRecorded: VisitObservation?

    init (profile: Profile,
          logger: Logger = DefaultLogger.shared) {
        self.historyHandler = profile.places
        self.logger = logger
    }

    func recordVisit(visitObservation: VisitObservation, isPrivateTab: Bool) {
        guard shouldRecordObservation(visitObservation: visitObservation, isPrivateTab: isPrivateTab) else { return }

        // Check this observation hasn't been recorded already
        if lastObservationRecorded?.url != visitObservation.url {
            let result = historyHandler.applyObservation(visitObservation: visitObservation)
            result.upon { [weak self] result in
                guard result.isSuccess else {
                    self?.logger.log(
                        result.failureValue?.localizedDescription ?? "Unknown error adding history visit",
                        level: .warning,
                        category: .sync
                    )
                    return
                }
                self?.lastObservationRecorded = visitObservation
            }
        }
    }

    // Based in user action like create new tab we reset the last visit observation
    func resetRecording() {
        lastObservationRecorded = nil
    }

    // Should record if is not Private tab, URL should not be ignored
    // or title is not empty
    private func shouldRecordObservation(visitObservation: VisitObservation, isPrivateTab: Bool) -> Bool {
        guard let title = visitObservation.title, !title.isEmpty,
              let url = URL(string: visitObservation.url), !isIgnoredURL(url),
              !isPrivateTab else {
            logger.log("Ignoring location change",
                       level: .debug,
                       category: .lifecycle)
            return false
        }

        return true
    }
}
