/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

class HistoryMetaDataViewModel {
    var historyMetaDataForTab: [URL : HistoryMetadata?] = [URL: HistoryMetadata?]()
    
    func updateHistorymetaData(url: String, profile: Profile) {
        do {            
//            let abc = profile.places.writer?.noteHistoryMetadataObservation(key: HistoryMetadataKey, observation: HistoryMetadataObservation)
// referrerUrl
//   - add it when you open a new tab from a url
//   - have a search term and follow-on url

// Group to be displayed in jump back in section
//            14 days days is the max time
//            let key = HistoryMetadataObservation()
             let historyMeta = try profile.places.reader?.getLatestHistoryMetadataForUrl(url: url)
            print(historyMeta)
        } catch  {
            print("ERR")
        }
    }
}
