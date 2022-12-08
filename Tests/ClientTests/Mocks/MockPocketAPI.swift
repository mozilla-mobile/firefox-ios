// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockPocketAPI: PocketStoriesProviding {
    init(result: Result<[PocketFeedStory], Error>) {
        self.result = result
    }

    var result: Result<[PocketFeedStory], Error>

    func fetchStories(items: Int, completion: @escaping (StoryResult) -> Void) {
        switch result {
        case .success(let value):
            completion(.success(Array(value.prefix(items))))
        case .failure(let error):
            completion(.failure(error))
        }
        return
    }
}
