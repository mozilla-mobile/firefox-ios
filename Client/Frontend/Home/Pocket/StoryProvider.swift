// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class StoryProvider: FeatureFlaggable {
    private let numberOfPocketStories: Int
    private let sponsoredIndices: [Int]

    init(
        pocketAPI: PocketStoriesProviding,
        pocketSponsoredAPI: PocketSponsoredStoriesProviding,
        numberOfPocketStories: Int = 11,
        sponsoredIndices: [Int] = [1, 9]
    ) {
        self.pocketAPI = pocketAPI
        self.pocketSponsoredAPI = pocketSponsoredAPI
        self.numberOfPocketStories = numberOfPocketStories
        self.sponsoredIndices = sponsoredIndices
    }

    private let pocketAPI: PocketStoriesProviding
    private let pocketSponsoredAPI: PocketSponsoredStoriesProviding

    private func insert(
        sponsoredStories: [PocketStory],
        into globalFeed: [PocketStory],
        indices: [Int]
    ) -> [PocketStory] {
        var global = globalFeed
        var sponsored = sponsoredStories
        for index in indices {
            // Making sure we insert a sponsored story at a valid index
            let normalisedIndex = min(index, global.endIndex)
            if let first = sponsored.first {
                global.insert(first, at: normalisedIndex)
                sponsored.removeAll(where: { $0 == first })
            }
        }
        return global
    }

    func fetchPocketStories() async -> [PocketStory] {
        let global = (try? await pocketAPI.fetchStories(items: numberOfPocketStories)) ?? []
        // Convert global feed to PocketStory
        var globalTemp = global.map(PocketStory.init)

        if featureFlags.isFeatureEnabled(.sponsoredPocket, checking: .buildAndUser),
           let sponsored = try? await pocketSponsoredAPI.fetchSponsoredStories() {
            // Convert sponsored feed to PocketStory, take the desired number of sponsored stories
            let sponsoredTemp = Array(sponsored.map(PocketStory.init).prefix(sponsoredIndices.count))
            globalTemp = Array(globalTemp.prefix(numberOfPocketStories - sponsoredIndices.count))
            globalTemp = insert(
                sponsoredStories: sponsoredTemp,
                into: globalTemp,
                indices: sponsoredIndices
            )
        }

        return globalTemp
    }
}
