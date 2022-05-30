// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

protocol PocketSponsoredStoriesProviderInterface {
    typealias SponsoredStoryResult = Swift.Result<[PocketSponsoredStory], Error>
    func fetchSponsoredStories(completion: @escaping (SponsoredStoryResult) -> Void)
    func fetchSponsoredStories() async throws -> [PocketSponsoredStory]
}

extension PocketSponsoredStoriesProviderInterface {
    func fetchSponsoredStories() async throws -> [PocketSponsoredStory] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchSponsoredStories { result in
                continuation.resume(with: result)
            }
        }
    }
}
