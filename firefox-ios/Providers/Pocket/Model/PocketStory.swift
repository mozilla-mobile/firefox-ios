// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct PocketStory: Equatable, Hashable {
    let url: URL?
    let title: String
    let domain: String
    let timeToRead: Int64?
    let storyDescription: String
    let imageURL: URL
    let id: Int?
    let flightId: Int?
    let campaignId: Int?
    let priority: Int?
    let context: String?
    let rawImageSrc: URL?
    let shim: PocketSponsoredStory.Shim?
    let caps: PocketSponsoredStory.Caps?
    let sponsor: String?
}

extension PocketStory {
    init(pocketFeedStory: PocketFeedStory) {
        self.title = pocketFeedStory.title
        self.url = pocketFeedStory.url
        self.domain = pocketFeedStory.domain
        self.timeToRead = pocketFeedStory.timeToRead
        self.storyDescription = pocketFeedStory.storyDescription
        self.imageURL = pocketFeedStory.imageURL
        self.id = nil
        self.flightId = nil
        self.campaignId = nil
        self.priority = nil
        self.context = nil
        self.rawImageSrc = nil
        self.shim = nil
        self.caps = nil
        self.sponsor = nil
    }

    init(pocketSponsoredStory: PocketSponsoredStory) {
        self.id = pocketSponsoredStory.id
        self.flightId = pocketSponsoredStory.flightId
        self.campaignId = pocketSponsoredStory.campaignId
        self.title = pocketSponsoredStory.title
        self.url = pocketSponsoredStory.url?.map(URL.init)
        self.domain = pocketSponsoredStory.domain
        self.storyDescription = pocketSponsoredStory.excerpt
        self.priority = pocketSponsoredStory.priority
        self.context = pocketSponsoredStory.context
        self.rawImageSrc = pocketSponsoredStory.rawImageSrc
        self.imageURL = pocketSponsoredStory.imageURL
        self.shim = pocketSponsoredStory.shim
        self.caps = pocketSponsoredStory.caps
        self.sponsor = pocketSponsoredStory.sponsor
        self.timeToRead = nil
    }
}
