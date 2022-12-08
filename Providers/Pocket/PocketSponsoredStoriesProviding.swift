// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

protocol PocketSponsoredStoriesProviding {
    typealias SponsoredStoryResult = Result<[PocketSponsoredStory], Error>

    func fetchSponsoredStories(timestamp: Timestamp, completion: @escaping (SponsoredStoryResult) -> Void)
    func fetchSponsoredStories(timestamp: Timestamp) async throws -> [PocketSponsoredStory]
}

extension PocketSponsoredStoriesProviding {
    func fetchSponsoredStories(timestamp: Timestamp = Date.now()) async throws -> [PocketSponsoredStory] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchSponsoredStories(timestamp: timestamp) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchSponsoredStories(completion: @escaping (SponsoredStoryResult) -> Void) {
        fetchSponsoredStories(timestamp: Date.now(), completion: completion)
    }
}
