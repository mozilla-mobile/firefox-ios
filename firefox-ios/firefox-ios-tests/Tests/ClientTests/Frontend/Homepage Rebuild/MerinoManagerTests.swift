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
<<<<<<< HEAD:firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Homepage Rebuild/PocketManagerTests.swift
        with pocketAPI: MockPocketAPI,
        file: StaticString = #file,
=======
        with merinoAPI: MockMerinoAPI,
        file: StaticString = #filePath,
>>>>>>> 72d19c08e (Add FXIOS-12218 [Homepage] Add Merino with AS client (#28099)):firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Homepage Rebuild/MerinoManagerTests.swift
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
