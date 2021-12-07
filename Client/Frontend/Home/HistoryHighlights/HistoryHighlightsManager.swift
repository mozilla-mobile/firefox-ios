// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import MozillaAppServices

//struct HistoryHighlightWeights {
//    let viewTime: Double
//    let frequency: Double
//
//    var asDictionary: [String: Double] {
//        return ["view_time": viewTime, "frequency": frequency]
//    }
//}

struct HistoryHighlight {
    let score: Double
    let placeID: Int
    let url: String
    let title: String?
    let previewImageURL: String?
}

class HistoryHighlightsManager {
    private static let defaultViewTimeWeight = 10.0
    private static let defaultFrequencyWeight = 4.0

    public static func getHistoryHighlights(with profile: Profile, using weight: HistoryHighlightWeights) {
//    , completion: @escaping ([ASGroup<T>]?, _ filteredItems: [T]) -> Void) {

        profile.places.getHighlights(
            weights: HistoryHighlightWeights(viewTime: self.defaultViewTimeWeight,
                                             frequency: self.defaultFrequencyWeight),
            limit: 200
        ).uponQueue(.main) { result in
            print("ROUX!!!!")
            print(result)
        }
    }

}
