// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@testable import Client

class MockSponsoredPocketAPI: PocketSponsoredStoriesProviding {
    init(result: Result<[PocketSponsoredStory], Error>) {
        self.result = result
    }

    var result: Result<[PocketSponsoredStory], Error>

    func fetchSponsoredStories(timestamp: Timestamp, completion: @escaping (SponsoredStoryResult) -> Void) {
        completion(result)
    }
}
