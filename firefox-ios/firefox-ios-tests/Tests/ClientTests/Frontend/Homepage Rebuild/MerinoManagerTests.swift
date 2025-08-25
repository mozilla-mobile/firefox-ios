// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

final class MerinoManagerTests: XCTestCase {
    func test_getMerinoItems_withSuccess_returnExpectedStories() async {
        let subject = createSubject(
            with: MockMerinoAPI(result: .success(getMockStoriesData()))
        )
        let stories = await subject.getMerinoItems()
        XCTAssertEqual(stories.count, 3)
    }

    func test_getMerinoItems_withSucess_returnEmptyStories() async {
        let subject = createSubject(
            with: MockMerinoAPI(result: .success([]))
        )
        let stories = await subject.getMerinoItems()
        XCTAssertEqual(stories.count, 0)
    }

    func test_getMerinoItems_withFailure_returnEmptyStories() async {
        let subject = createSubject(
            with: MockMerinoAPI(result: .failure(TestError.example))
        )
        let stories = await subject.getMerinoItems()
        XCTAssertEqual(stories.count, 0)
    }

    private func createSubject(
        with merinoAPI: MockMerinoAPI,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MerinoManager {
        let subject = MerinoManager(merinoAPI: merinoAPI)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func getMockStoriesData() -> [RecommendationDataItem] {
        return [
            .makeItem("feed1"),
            .makeItem("feed2"),
            .makeItem("feed3"),
        ]
    }

    enum TestError: Error {
        case example
    }
}
