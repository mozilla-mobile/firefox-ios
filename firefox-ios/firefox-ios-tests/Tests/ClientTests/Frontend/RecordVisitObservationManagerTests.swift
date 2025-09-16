// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

final class MockHistoryHandler: HistoryHandler {
    var applied: [VisitObservation] = []
    var appplyObservationCallCount = 0
    var nextResult: Result<Void, Error> = .success(())

    var onApply: ((Success) -> Void)?

    // Success = Deferred<Maybe<Void>>
    func applyObservation(visitObservation: VisitObservation) -> Success {
        applied.append(visitObservation)
        let result = Success()

        DispatchQueue.main.async {
            result.fill(.success(()))
            self.onApply?(result)
        }
        return result
    }

    /*
     func getBookmarksTree(rootGUID: Shared.GUID, recursive: Bool) -> Deferred<Maybe<BookmarkNodeData?>> {
         let deferred = Deferred<Maybe<BookmarkNodeData?>>()
         deferred.fill(Maybe(success: bookmarkFolderData))
         return deferred
     }

     func getBookmarksTree(
         rootGUID: GUID,
         recursive: Bool,
         completion: @escaping (Result<BookmarkNodeData?, any Error>) -> Void
     ) {
         completion(.success(bookmarkFolderData))
     }
     */
}

final class RecordVisitObservationManagerTests: XCTestCase {
    private var historyHandler: MockHistoryHandler!
    private var logger: MockLogger!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        historyHandler = MockHistoryHandler()
        logger = MockLogger()
        profile = MockProfile()
    }

    override func tearDown() {
        profile = nil
        logger = nil
        historyHandler = nil
        super.tearDown()
    }

    func testRecordVisitRecordsAndUpdatesLastObservation() {
        let subject = createSubject()
        let observation = createObservation()

        let exp = expectation(description: "applyObservation finished")
        historyHandler.onApply = { deferred in
            deferred.upon { _ in
                DispatchQueue.main.async {
                    exp.fulfill()
                }
            }
        }

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(historyHandler.applied.count, 1)
        XCTAssertEqual(historyHandler.applied.first?.url, observation.url)
        print("--- YRD checking observation")
        XCTAssertEqual(subject.lastObservationRecorded?.url, observation.url)
    }

    func testRecordVisitDedupesSameURLNotRecordedTwice() {
        let subject = createSubject()
        let observation1 = createObservation(url: "https://example.com/a", title: "A")
        let observation2 = createObservation(url: "https://example.com/a", title: "A again")

        subject.recordVisit(visitObservation: observation1, isPrivateTab: false)
        subject.recordVisit(visitObservation: observation2, isPrivateTab: false)

        print("--- YRD checking observation")
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

    func test_recordVisit_aboutURL_doesNotRecord() {
        // about: scheme should be ignored by isValidURLToRecord path
        let subject = createSubject()
        let observation = createObservation(url: "about:preferences", title: "About Prefs")

        subject.recordVisit(visitObservation: observation, isPrivateTab: false)

        XCTAssertTrue(historyHandler.applied.isEmpty)
        XCTAssertNil(subject.lastObservationRecorded)
    }

    func testRecordVisitLocalhostURLDoesNotRecord() {
        // localhost should be ignored
        let subject = createSubject()
        let observation = createObservation(url: "http://localhost:8080/", title: "Localhost")

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
