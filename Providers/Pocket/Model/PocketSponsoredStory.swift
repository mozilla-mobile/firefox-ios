// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct PocketSponsoredStory: Codable {
    let id: Int
    let flightId: Int
    let campaignId: Int
    let title: String
    let url: String?
    let domain: String
    let excerpt: String
    let priority: Int
    let context: String
    let rawImageSrc: URL
    let imageURL: URL
    let shim: Shim
    let caps: Caps
    let sponsor: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case flightId = "flight_id"
        case campaignId = "campaign_id"
        case title = "title"
        case url = "url"
        case domain = "domain"
        case excerpt = "excerpt"
        case priority = "priority"
        case context = "context"
        case rawImageSrc = "raw_image_src"
        case imageURL = "image_src"
        case shim = "shim"
        case caps = "caps"
        case sponsor = "sponsor"
    }

    struct Shim: Codable {
        let click: String
        let impression: String
        let delete: String
        let save: String
    }

    struct Caps: Codable {
        let lifetime: Int
        let campaign: Limit
        let flight: Limit

        struct Limit: Codable {
            let count: Int
            let period: Int
        }
    }
}

struct PocketSponsoredRequest: Codable {
    let spocs: [PocketSponsoredStory]
}
