// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

struct MerinoStory: Equatable, Hashable {
    let corpusItemId: String
    let scheduledCorpusItemId: String
    let url: URL
    let title: String
    let excerpt: String
    let topic: String?
    let publisher: String
    let isTimeSensitive: Bool
    let imageUrl: URL
    let iconUrl: URL?
    let tileId: Int64
    let receivedRank: Int

    init(from item: RecommendationDataItem) {
        self.corpusItemId = item.corpusItemId
        self.scheduledCorpusItemId = item.scheduledCorpusItemId
        self.url = URL(string: item.url)!
        self.title = item.title
        self.excerpt = item.excerpt
        self.topic = item.topic
        self.publisher = item.publisher
        self.isTimeSensitive = item.isTimeSensitive
        self.imageUrl = URL(string: item.imageUrl)!
        self.iconUrl = item.iconUrl.flatMap(URL.init(string:))
        self.tileId = item.tileId
        self.receivedRank = Int(item.receivedRank)
    }
}

