// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

<<<<<<< HEAD:firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Home/Pocket/PocketDataAdaptorTests.swift
class PocketDataAdaptorTests: XCTestCase {
=======
@MainActor
class StoryDataAdaptorTests: XCTestCase {
>>>>>>> 72d19c08e (Add FXIOS-12218 [Homepage] Add Merino with AS client (#28099)):firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Home/Stories/StoryDataAdaptorTests.swift
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
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]
        mockMerinoAPI = MockMerinoAPI(result: .success(stories))
        let subject = createSubject()
<<<<<<< HEAD:firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Home/Pocket/PocketDataAdaptorTests.swift
        let data = subject.getPocketData()
        try await Task.sleep(nanoseconds: sleepTime)
=======
        try await Task.sleep(nanoseconds: sleepTime)
        let data = subject.getMerinoData()
>>>>>>> 72d19c08e (Add FXIOS-12218 [Homepage] Add Merino with AS client (#28099)):firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Home/Stories/StoryDataAdaptorTests.swift
        XCTAssertEqual(data.count, 3, "Data should contain three pocket stories")
    }

<<<<<<< HEAD:firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Home/Pocket/PocketDataAdaptorTests.swift
// MARK: Helper
private extension PocketDataAdaptorTests {
    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> PocketDataAdaptorImplementation {
        let expectation = expectation(description: "Expect pocket adaptor to be created and fetch data")
        let subject = PocketDataAdaptorImplementation(pocketAPI: mockPocketAPI,
                                                      notificationCenter: mockNotificationCenter) {
            expectation.fulfill()
        }
=======
    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> StoryDataAdaptorImplementation {
        let subject = StoryDataAdaptorImplementation(
            merinoAPI: mockMerinoAPI,
            notificationCenter: mockNotificationCenter
        )
>>>>>>> 72d19c08e (Add FXIOS-12218 [Homepage] Add Merino with AS client (#28099)):firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Home/Stories/StoryDataAdaptorTests.swift
        trackForMemoryLeaks(subject, file: file, line: line)
        wait(for: [expectation], timeout: 1)
        return subject
    }
}
