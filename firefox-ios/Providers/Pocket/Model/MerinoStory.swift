// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

struct MerinoStory: Equatable, Hashable {
    let corpusItemId: String
    let scheduledCorpusItemId: String
    let url: URL?
    let title: String
    let excerpt: String
    let topic: String?
    let publisher: String
    let isTimeSensitive: Bool
    let imageURL: URL
    let iconURL: URL?
    let tileId: Int64
    let receivedRank: Int

    init(from item: RecommendationDataItem) {
        self.corpusItemId = item.corpusItemId
        self.scheduledCorpusItemId = item.scheduledCorpusItemId
        self.url = URL(string: item.url)
        self.title = item.title
        self.excerpt = item.excerpt
        self.topic = item.topic
        self.publisher = item.publisher
        self.isTimeSensitive = item.isTimeSensitive
        self.imageURL = URL(string: item.imageUrl)!
        self.iconURL = item.iconUrl.flatMap(URL.init(string:))
        self.tileId = item.tileId
        self.receivedRank = Int(item.receivedRank)
    }

    init(
        corpusItemId: String,
        scheduledCorpusItemId: String,
        url: URL?,
        title: String,
        excerpt: String,
        topic: String?,
        publisher: String,
        isTimeSensitive: Bool,
        imageURL: URL,
        iconURL: URL?,
        tileId: Int64,
        receivedRank: Int
    ) {
        self.corpusItemId = corpusItemId
        self.scheduledCorpusItemId = scheduledCorpusItemId
        self.url = url
        self.title = title
        self.excerpt = excerpt
        self.topic = topic
        self.publisher = publisher
        self.isTimeSensitive = isTimeSensitive
        self.imageURL = imageURL
        self.iconURL = iconURL
        self.tileId = tileId
        self.receivedRank = receivedRank
    }
}
