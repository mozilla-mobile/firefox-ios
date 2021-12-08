// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import MozillaAppServices

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

    public static func getHighlightsForRecentlyViewed(with profile: Profile, completion: @escaping ([MozillaAppServices.HistoryHighlight]) -> Void) {

        profile.places.getHighlights(
            weights: HistoryHighlightWeights(viewTime: self.defaultViewTimeWeight,
                                             frequency: self.defaultFrequencyWeight),
            limit: 200
        ).uponQueue(.main) { result in
            print("ROUX!!!!")
            if let results = result.successValue {
                print(results)
            }
            guard let highlights = result.successValue else { return completion([]) }

            completion(highlights)
        }
    }

}
