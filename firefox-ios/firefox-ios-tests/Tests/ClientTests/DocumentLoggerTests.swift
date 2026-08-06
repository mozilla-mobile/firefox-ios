// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import TestKit
import XCTest
@testable import Client

@MainActor
final class DocumentLoggerTests: XCTestCase {
    private var logger: MockLogger!

    override func setUp() async throws {
        try await super.setUp()
        logger = MockLogger()
    }

    override func tearDown() async throws {
        logger = nil
        try await super.tearDown()
    }

    func testLogPendingDownloads_logOnlineURL() throws {
        let subject = createSubject()

        subject.registerDownloadStart(url: URL(string: "https://www.example.com")!)
        subject.logPendingDownloads()

        let pendingDownloads = Int(try XCTUnwrap(logger.savedExtra?[subject.downloadExtraKey]))

        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(pendingDownloads, 1)
    }

    func testLogPendingsDownloads_doesntLogOfflineURL() throws {
        let subject = createSubject()

        subject.registerDownloadStart(url: URL(fileURLWithPath: "test.pdf"))
        subject.logPendingDownloads()

        XCTAssertNil(logger.savedExtra?[subject.downloadExtraKey])
    }

    func testLogPendingsDownloads_doesntLogWhenDownloadRemoved() {
        let subject = createSubject()
        let url = URL(string: "https://www.example.com")!

        subject.registerDownloadStart(url: url)
        subject.remove(url: url)
        subject.logPendingDownloads()

        XCTAssertNil(logger.savedExtra?[subject.downloadExtraKey])
    }

    func testLogPendingsDownloads_doesntLogWhenDownloadCompleted() {
        let subject = createSubject()
        let url = URL(string: "https://www.example.com")!

        subject.registerDownloadStart(url: url)
        subject.registerDownloadFinish(url: url)
        subject.logPendingDownloads()

        XCTAssertNil(logger.savedExtra?[subject.downloadExtraKey])
    }

    func testRegisterDownloadFinish_missingDocument_logsWithoutExtra() {
        let subject = createSubject()

        subject.registerDownloadFinish(url: URL(string: "https://www.example.com")!)

        XCTAssertEqual(logger.savedMessage, "Document is missing but finished downloading")
        XCTAssertEqual(logger.savedLevel, .info)
        XCTAssertNil(logger.savedExtra)
    }

    func testRegisterDownloadFinish_registeredDocument_doesntLog() {
        let subject = createSubject()
        let url = URL(string: "https://www.example.com")!

        subject.registerDownloadStart(url: url)
        subject.registerDownloadFinish(url: url)

        XCTAssertNil(logger.savedMessage)
    }

    private func createSubject() -> DocumentLogger {
        let logger = DocumentLogger(logger: logger)
        trackForMemoryLeaks(logger)
        return logger
    }
}
