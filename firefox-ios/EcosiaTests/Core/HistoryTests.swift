// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class HistoryTests: XCTestCase {
    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.pages)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.pages)
    }

    func testSave() {
        let expect = expectation(description: "")
        let history = History()
        history.add(.init(url: URL(string: "https://avocado.com")!, title: "hello world"))
        PageStore.queue.async {
            XCTAssertTrue(FileManager.default.fileExists(atPath: FileManager.history.path))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testLoad() {
        let expect = expectation(description: "")
        var history = History()
        history.add(.init(url: URL(string: "https://avocado.com")!, title: "hello world"))
        history.add(.init(url: URL(string: "https://guacamole.com")!, title: "lorem ipsum"))
        PageStore.queue.async {
            history = .init()
            PageStore.queue.async {
                XCTAssertGreaterThan(history.items.first!.0, Date(timeIntervalSince1970: 1))
                XCTAssertGreaterThan(history.items.last!.0, Date(timeIntervalSince1970: 1))
                XCTAssertEqual("hello world", history.items.first?.1.title)
                XCTAssertEqual("lorem ipsum", history.items.last?.1.title)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testDelete() {
        let expect = expectation(description: "")
        var history = History()
        history.add(.init(url: URL(string: "https://avocado.com")!, title: "hello world"))
        PageStore.queue.async {
            history = .init()
            history.delete(history.items.first!.0)
            PageStore.queue.async {
                XCTAssertTrue(History().items.isEmpty)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testDeleteAll() {
        let expect = expectation(description: "")
        var history = History()
        history.add(.init(url: URL(string: "https://avocado.com")!, title: "hello world"))
        history.add(.init(url: URL(string: "https://guacamlo.com")!, title: "lorem ipsum"))
        PageStore.queue.async {
            history = .init()
            history.deleteAll()
            PageStore.queue.async {
                XCTAssertTrue(History().items.isEmpty)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
}
