// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

@testable import Client

<<<<<<< HEAD
final class MockPocketManager: PocketManagerProvider {
    var getPocketItemsCalled = 0
    func getPocketItems() async -> [PocketStoryConfiguration] {
        getPocketItemsCalled += 1
        let stories: [PocketFeedStory] = [
=======
final class MockMerinoManager: MerinoManagerProvider, @unchecked Sendable {
    var getMerinoItemsCalled = 0

    func getMerinoItems() async -> [MerinoStoryConfiguration] {
        getMerinoItemsCalled += 1
        let stories: [RecommendationDataItem] = [
>>>>>>> 72d19c08e (Add FXIOS-12218 [Homepage] Add Merino with AS client (#28099))
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        return stories.compactMap { MerinoStoryConfiguration(story: MerinoStory(from: $0)) }
    }
}
