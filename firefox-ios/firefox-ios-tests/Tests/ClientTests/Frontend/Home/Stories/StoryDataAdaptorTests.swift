// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

@MainActor
class StoryDataAdaptorTests: XCTestCase {
    private let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    var mockNotificationCenter: MockNotificationCenter!
    var mockMerinoAPI: MockMerinoAPI!

    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        mockNotificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        super.tearDown()
        mockNotificationCenter = nil
        mockMerinoAPI = nil
    }

    func testEmptyData() async throws {
        mockMerinoAPI = MockMerinoAPI(result: .success([]))
        let subject = createSubject()
        try await Task.sleep(nanoseconds: sleepTime)
        let data = subject.getMerinoData()
        XCTAssertEqual(data.count, 0, "Data should be null")
    }

    func testGetPocketData() async throws {
        let stories: [RecommendationDataItem] = [
            .makeItem("feed1"),
            .makeItem("feed2"),
            .makeItem("feed3"),
        ]
        mockMerinoAPI = MockMerinoAPI(result: .success(stories))
        let subject = createSubject()
        try await Task.sleep(nanoseconds: sleepTime)
        let data = subject.getMerinoData()
        XCTAssertEqual(data.count, 3, "Data should contain three pocket stories")
    }

    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> StoryDataAdaptorImplementation {
        let subject = StoryDataAdaptorImplementation(
            merinoAPI: mockMerinoAPI,
            notificationCenter: mockNotificationCenter
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
