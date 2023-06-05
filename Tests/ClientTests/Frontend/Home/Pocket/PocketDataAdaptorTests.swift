// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class PocketDataAdaptorTests: XCTestCase {
    var mockNotificationCenter: MockNotificationCenter!
    var mockPocketAPI: MockPocketAPI!

    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        mockNotificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        super.tearDown()
        mockNotificationCenter = nil
        mockPocketAPI = nil
    }

    func testEmptyData() {
        mockPocketAPI = MockPocketAPI(result: .success([]))
        let subject = createSubject()
        let data = subject.getPocketData()
        XCTAssertEqual(data.count, 0, "Data should be null")
    }

    func testGetPocketData() {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]
        mockPocketAPI = MockPocketAPI(result: .success(stories))
        let subject = createSubject()
        let data = subject.getPocketData()
        XCTAssertEqual(data.count, 3, "Data should contain three pocket stories")
    }

    func testNotificationUpdatesData() {
        mockPocketAPI = MockPocketAPI(result: .success([]))
        var sentOnce = false
        let subject = createSubject(expectedFulfillmentCount: 2) {
            guard !sentOnce else { return }
            sentOnce = true

            let stories: [PocketFeedStory] = [
                .make(title: "feed1"),
                .make(title: "feed2"),
                .make(title: "feed3"),
            ]
            self.mockPocketAPI.result = .success(stories)
            self.mockNotificationCenter.post(name: UIApplication.willEnterForegroundNotification)
        }

        let data = subject.getPocketData()
        XCTAssertEqual(data.count, 3, "Data should contain three pocket stories")
    }
}

// MARK: Helper
private extension PocketDataAdaptorTests {
    func createSubject(expectedFulfillmentCount: Int = 1,
                       dataCompletion: (() -> Void)? = nil,
                       file: StaticString = #file,
                       line: UInt = #line) -> PocketDataAdaptorImplementation {
        let pocketSponsoredAPI = MockSponsoredPocketAPI(result: .success([]))

        let expectation = expectation(description: "Expect pocket adaptor to be created and fetch data")
        expectation.expectedFulfillmentCount = expectedFulfillmentCount
        let subject = PocketDataAdaptorImplementation(pocketAPI: mockPocketAPI,
                                                      pocketSponsoredAPI: pocketSponsoredAPI,
                                                      notificationCenter: mockNotificationCenter) {
            expectation.fulfill()
            dataCompletion?()
        }
        mockNotificationCenter.notifiableListener = subject
        trackForMemoryLeaks(subject, file: file, line: line)
        wait(for: [expectation], timeout: 1)
        return subject
    }
}
