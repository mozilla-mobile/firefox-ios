// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

final class MerinoManagerTests: XCTestCase {
    func test_getPocketItems_withSuccess_returnExpectedStories() async {
        let subject = createSubject(
            with: MockMerinoAPI(result: .success(getMockStoriesData()))
        )
        let stories = await subject.getMerinoItems()
        XCTAssertEqual(stories.count, 3)
    }

    func test_getPocketItems_withSucess_returnEmptyStories() async {
        let subject = createSubject(
            with: MockMerinoAPI(result: .success([]))
        )
        let stories = await subject.getMerinoItems()
        XCTAssertEqual(stories.count, 0)
    }

    func test_getPocketItems_withFailure_returnEmptyStories() async {
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
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]
    }

    enum TestError: Error {
        case example
    }
}
