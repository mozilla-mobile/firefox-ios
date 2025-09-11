// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import WebKit

// Handles recording visit to website that will be used to list History
struct RecordVisitObservationManager {
    // some kind of mech to avoid recording same observation twice based in user actions like new tab
    private var historyHandler: HistoryHandler
    nonisolated let logger: Logger

    init (profile: Profile,
          logger: Logger = DefaultLogger.shared) {
        self.historyHandler = profile.places
        self.logger = logger
    }

    func recordVisit(visitObservation: VisitObservation, isPrivateTab: Bool) {
        guard shouldRecordObservation(visitObservation: visitObservation, isPrivateTab: isPrivateTab) else { return }

        let result = historyHandler.applyObservation(visitObservation: visitObservation)
        result.upon { result in
            guard result.isSuccess else {
                self.logger.log(
                    result.failureValue?.localizedDescription ?? "Unknown error adding history visit",
                    level: .warning,
                    category: .sync
                )
                return
            }
        }
    }

    // Should record if is not Private tab
    // if URL should not be ignored
    // or title is empty
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
    
    /*
     @objc
     func onLocationChange(notification: NSNotification) {
         let v = notification.userInfo!["visitType"] as? Int
         let visitType = VisitType.fromRawValue(rawValue: v)
         if let url = notification.userInfo!["url"] as? URL, !isIgnoredURL(url),
            let title = notification.userInfo!["title"] as? NSString {
             // Only record local visits if the change notification originated from a non-private tab
             if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                 let visitObservation = VisitObservation(
                     url: url.description,
                     title: title as String,
                     visitType: visitType
                 )
                 let result = self.places.applyObservation(visitObservation: visitObservation)
                 result.upon { result in
                     guard result.isSuccess else {
                         self.logger.log(
                             result.failureValue?.localizedDescription ?? "Unknown error adding history visit",
                             level: .warning,
                             category: .sync
                         )
                         return
                     }
                 }
             }
         } else {
             logger.log("Ignoring location change",
                        level: .debug,
                        category: .lifecycle)
         }
     }
     */
}
