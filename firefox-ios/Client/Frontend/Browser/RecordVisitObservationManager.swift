// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import WebKit

// Handles recording visits to websites, which will be displayed in the History Panel.
protocol RecordVisitObserving: AnyObject {
    func recordVisit(visitObservation: VisitObservation, isPrivateTab: Bool)
    func resetRecording()
}

// TODO: FXIOS-14364: RecordVisitObservationManager should not be @unchecked Sendable
class RecordVisitObservationManager: RecordVisitObserving, @unchecked Sendable {
    private var historyHandler: HistoryHandler
    let logger: Logger
    var lastObservationRecorded: VisitObservation?

    init(historyHandler: HistoryHandler,
         logger: Logger = DefaultLogger.shared) {
        self.historyHandler = historyHandler
        self.logger = logger
    }

    func recordVisit(visitObservation: VisitObservation, isPrivateTab: Bool) {
        guard shouldRecordObservation(visitObservation: visitObservation, isPrivateTab: isPrivateTab) else { return }

        // Check this observation hasn't been recorded already
        guard lastObservationRecorded?.url != visitObservation.url else { return }

        historyHandler.applyObservation(visitObservation: visitObservation) { [weak self] result in
            switch result {
            case .success:
                self?.lastObservationRecorded = visitObservation
            case .failure(let error):
                self?.logger.log(error.localizedDescription,
                                 level: .warning,
                                 category: .sync)
            }
        }
    }

    // Based on user actions like creating a new tab, we reset the last visit observation.
    func resetRecording() {
        lastObservationRecorded = nil
    }

    // Record visits for websites that are not in a private tab, have non-empty titles,
    // and are not URLs that we ignore (localhost and about schemes).
    private func shouldRecordObservation(visitObservation: VisitObservation, isPrivateTab: Bool) -> Bool {
        guard let title = visitObservation.title, !title.isEmpty,
              !isPrivateTab,
              isValidURLToRecord(url: visitObservation.url) else {
            logger.log("Ignoring location change",
                       level: .debug,
                       category: .lifecycle)
            return false
        }

        return true
    }

    private func isValidURLToRecord(url: Url) -> Bool {
        guard let url = URL(string: url) else { return false }

        return !isIgnoredURL(url) && (!InternalURL.isValid(url: url) || url.isReaderModeURL) && !url.isFileURL
    }
}
