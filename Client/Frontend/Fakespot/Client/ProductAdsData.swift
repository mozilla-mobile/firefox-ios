// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ProductAdsData: Codable {
    let name: String
    let url: URL
    let imageUrl: URL
    let price: String
    let currency: String
    let grade: String
    let adjustedRating: Double
    let analysisUrl: URL
    let sponsored: Bool
    let aid: String

     private enum CodingKeys: String, CodingKey {
         case name
         case url
         case imageUrl = "image_url"
         case price
         case currency
         case grade
         case adjustedRating = "adjusted_rating"
         case analysisUrl = "analysis_url"
         case sponsored
         case aid
     }
}
