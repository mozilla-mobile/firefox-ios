// swiftlint:disable force_try
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class NewsTests: XCTestCase {
    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.news)
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.news)
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    private func mockSavedItems() {
        let items = [
            NewsModel(
                id: 1,
                text: "",
                language: .en,
                publishDate: .distantPast,
                imageUrl: URL(string: "https://avocade.com")!,
                targetUrl: URL(string: "https://avocadoe.com")!,
                trackingName: ""
            ),
            NewsModel(
                id: 2,
                text: "hello",
                language: .en,
                publishDate: .distantFuture,
                imageUrl: URL(string: "https://guacamole.com")!,
                targetUrl: URL(string: "https://guaca.com")!,
                trackingName: ""
            ),
            NewsModel(
                id: 3,
                text: "hello",
                language: .de,
                publishDate: .distantFuture,
                imageUrl: URL(string: "https://guacamole.com")!,
                targetUrl: URL(string: "https://guaca.com")!,
                trackingName: ""
            )
        ]
        try? JSONEncoder().encode(items).write(to: FileManager.news, options: .atomic)
    }

    func testPublishOnMainThread() {
        let expect = expectation(description: "")

        mockSavedItems()
        let notifications = News()
        notifications.subscribe(self) { _ in
            XCTAssertEqual(.main, Thread.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testLoadFromDisk() {
        let expect = expectation(description: "")
        mockSavedItems()

        let notifications = News()
        notifications.subscribe(self) {
            XCTAssertEqual(2, $0.count)
            $0.forEach {
                XCTAssertEqual(.en, $0.language)
            }
            XCTAssertGreaterThan($0.first!.publishDate, $0.last!.publishDate)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAvoidDuplication() {
        var set = Set([
            NewsModel(
                id: 1,
                text: "<strong>Great headline</strong> ",
                language: .en,
                publishDate: .distantPast,
                imageUrl: URL(string: "https://avocade.com")!,
                targetUrl: URL(string: "https://avocadoe.com")!,
                trackingName: ""
            )
        ])
        set.insert(
            NewsModel(
                id: 1,
                text: "hello",
                language: .de,
                publishDate: .distantFuture,
                imageUrl: URL(string: "https://guacamole.com")!,
                targetUrl: URL(string: "https://guaca.com")!,
                trackingName: ""
            )
        )
        XCTAssertEqual(1, set.count)
    }

    func testLoadNewForced() {
        User.shared.news = Date()

        let expect = expectation(description: "")
        let session = MockURLSession()
        session.data = [try! .init(contentsOf: Bundle.ecosiaTests.url(forResource: "notifications", withExtension: "json")!)]

        let notifications = News()
        notifications.subscribe(self) {
            XCTAssertEqual(10, $0.count)
            XCTAssertGreaterThan($0.first!.publishDate, $0.last!.publishDate)

            expect.fulfill()
        }
        notifications.load(session: session)
        waitForExpectations(timeout: 1)
    }

    func testNeedsUpdateOnEmptyNews() {
        let news = News()
        XCTAssertTrue(news.needsUpdate)
    }

    func testNeedsUpdateAfterLoading() {
        let expect = expectation(description: "")
        mockSavedItems()
        User.shared.news = .distantPast
        let news = News()

        news.subscribe(self) { _ in
            XCTAssertTrue(news.needsUpdate)

            User.shared.news = Date()
            XCTAssertFalse(news.needsUpdate)

            User.shared.news = Date().advanced(by: -25 * 60 * 60)
            XCTAssertTrue(news.needsUpdate)

            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSubscribeAndReceive() {
        let expect = expectation(description: "")
        let news = News()

        news.subscribeAndReceive(self) { items in
            XCTAssert(news.state?.count == items.count)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCallOnFailed() {
        let expect = expectation(description: "")
        expect.isInverted = true // we expect no callback
        let session = MockURLSession()
        let notifications = News()
        notifications.subscribe(self) { _ in
            expect.fulfill()
        }
        notifications.load(session: session)
        waitForExpectations(timeout: 1)
    }

    func testCleanTextFromBundle() {
        let expect = expectation(description: "")
        mockSavedItems()
        let notifications = News()
        notifications.subscribe(self) {
            $0.forEach {
                XCTAssertFalse($0.text.contains("&#39;"))
                XCTAssertFalse($0.text.contains("<strong>"))
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCleanTextFromNetwork() {
        let expect = expectation(description: "")
        let session = MockURLSession()
        session.data = [try! .init(contentsOf: Bundle.ecosiaTests.url(forResource: "notifications", withExtension: "json")!)]
        let notifications = News()
        notifications.subscribe(self) {
            $0.forEach {
                XCTAssertFalse($0.text.contains("&#39;"))
                XCTAssertFalse($0.text.contains("<strong>"))
            }
            expect.fulfill()
        }
        notifications.load(session: session)
        waitForExpectations(timeout: 1)
    }
}
// swiftlint:enable force_try
