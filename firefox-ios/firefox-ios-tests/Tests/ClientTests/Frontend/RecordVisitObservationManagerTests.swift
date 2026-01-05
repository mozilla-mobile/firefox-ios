// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common
import XCTest

@testable import Client

@MainActor
final class RecordVisitObservationManagerTests: XCTestCase {
    private var historyHandler: MockHistoryHandler!
    private var logger: MockLogger!
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        historyHandler = MockHistoryHandler()
        logger = MockLogger()
        profile = MockProfile()
    }

    override func tearDown() async throws {
        profile = nil
        logger = nil
        historyHandler = nil
        try await super.tearDown()
    }

    func testRecordVisitRecordsAndUpdatesLastObservation() {
        let subject = createSubject()
        let observation = createObservation()

        let exp = expectation(description: "applyObservation finished")
        historyHandler.onApply = {
           exp.fulfill()
        }

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(historyHandler.applied.count, 1)
        XCTAssertEqual(historyHandler.applied.first?.url, observation.url)
        XCTAssertEqual(subject.lastObservationRecorded?.url, observation.url)
    }

    func testRecordVisitRecordsTwoUniqueURLsAndLastObservationIsCorrect() {
        let subject = createSubject()
        let observation1 = createObservation(url: "https://example.com/first", title: "First site")
        let observation2 = createObservation(url: "https://example.com/second", title: "Second site")
        let appliedTwice = expectation(description: "onApply called twice")
        appliedTwice.expectedFulfillmentCount = 2

        historyHandler.onApply = {
            appliedTwice.fulfill()
        }

        subject.recordVisit(visitObservation: observation1, isPrivateTab: false)
        subject.recordVisit(visitObservation: observation2, isPrivateTab: false)

        wait(for: [appliedTwice], timeout: 2.0)

        // Assert
        XCTAssertEqual(historyHandler.applied.count, 2, "onApply should be called once per unique URL")
        XCTAssertEqual(historyHandler.applied[0].url, observation1.url)
        XCTAssertEqual(historyHandler.applied[1].url, observation2.url)

        if let latest = subject.lastObservationRecorded {
            XCTAssertEqual(latest.url, observation2.url)
        }
    }

    func testRecordVisitDedupesSameURLNotRecordedTwice() {
        let subject = createSubject()
        let observation1 = createObservation(url: "https://example.com/a", title: "A")
        let observation2 = createObservation(url: "https://example.com/a", title: "A again")

        let exp = expectation(description: "applyObservation finished")
        historyHandler.onApply = {
           exp.fulfill()
        }

        subject.recordVisit(visitObservation: observation1, isPrivateTab: false)
        subject.recordVisit(visitObservation: observation2, isPrivateTab: false)
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(historyHandler.applied.count, 1)
        XCTAssertEqual(subject.lastObservationRecorded?.url, observation1.url)
    }

    func testRecordVisitPrivateTabDoesNotRecord() {
        let subject = createSubject()
        let observation = createObservation()

        subject.recordVisit(visitObservation: observation, isPrivateTab: true)

        XCTAssertTrue(historyHandler.applied.isEmpty)
        XCTAssertNil(subject.lastObservationRecorded)
    }

    func testRecordVisitEmptyTitleDoesNotRecord() {
        let subject = createSubject()
        let observation = createObservation(title: "")

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)

        XCTAssertTrue(historyHandler.applied.isEmpty)
        XCTAssertNil(subject.lastObservationRecorded)
    }

    func testRecordVisitAboutURLDoesNotRecord() {
        // about: scheme should be ignored by isValidURLToRecord path
        // because it is an ignored URL scheme
        let subject = createSubject()
        let observation = createObservation(url: "about:preferences", title: "About Prefs")

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)

        XCTAssertTrue(historyHandler.applied.isEmpty)
        XCTAssertNil(subject.lastObservationRecorded)
    }

    func testRecordVisitLocalhostURLDoesNotRecord() {
        // localhost should be ignored by isValidURLToRecord path
        // because it is an ignored URL scheme (unless it's for `test-fixture`)
        let subject = createSubject()
        let observation = createObservation(url: "http://localhost:8080/", title: "Localhost")

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)

        XCTAssertTrue(historyHandler.applied.isEmpty)
        XCTAssertNil(subject.lastObservationRecorded)
    }

    func testRecordVisitReaderModeURLDoesNotRecord() {
        // reader-mode should be ignored by isValidURLToRecord
        let subject = createSubject()
        let url = "http://localhost:\(AppInfo.webserverPort)/reader-mode/page"
        let observation = createObservation(url: url, title: "Reader Mode")

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)

        XCTAssertTrue(historyHandler.applied.isEmpty)
        XCTAssertNil(subject.lastObservationRecorded)
    }

    func testRecordVisitFileURLDoesNotRecord() {
        let subject = createSubject()
        let observation = createObservation(url: "file:///Users/me/index.html", title: "File")

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)

        XCTAssertTrue(historyHandler.applied.isEmpty)
        XCTAssertNil(subject.lastObservationRecorded)
    }

    func testResetRecordingSetsLastObservationToNil() {
        let subject = createSubject()
        subject.lastObservationRecorded = createObservation()
        subject.resetRecording()

        XCTAssertNil(subject.lastObservationRecorded)
    }

    // MARK: - Private helpers

    private func createSubject() -> RecordVisitObservationManager {
        let manager = RecordVisitObservationManager(historyHandler: historyHandler, logger: logger)

        trackForMemoryLeaks(manager)
        return manager
    }

    private func createObservation(url: String = "https://example.com/",
                                   title: String? = "Example",
                                   visitType: VisitType = .link) -> VisitObservation {
        return VisitObservation(url: url, title: title, visitType: visitType)
    }
}
