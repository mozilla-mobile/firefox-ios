// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class TabsTests: XCTestCase {
    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.pages)
        try? FileManager.default.removeItem(at: FileManager.snapshots)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.pages)
        try? FileManager.default.removeItem(at: FileManager.snapshots)
    }

    func testNew() {
        let tabs = Tabs()
        XCTAssertTrue(tabs.items.isEmpty)
        XCTAssertNil(tabs.current)
    }

    func testAdd() {
        let expect = expectation(description: "")
        let url = URL(string: "https://www.avocado.com")!
        let tabs = Tabs()
        tabs.new(url)
        XCTAssertEqual(url, tabs.items.first?.page?.url)
        XCTAssertEqual(0, tabs.current)
        PageStore.queue.async {
            XCTAssertFalse(((try? Data(contentsOf: FileManager.tabs)) ?? Data()).isEmpty)
            XCTAssertFalse(((try? Data(contentsOf: FileManager.currentTab)) ?? Data()).isEmpty)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testLoad() {
        let expect = expectation(description: "")
        let urlFirst = URL(string: "https://www.avocado.com")!
        let urlSecond = URL(string: "https://www.trees.com")!
        var tabs = Tabs()
        tabs.new(urlFirst)
        tabs.new(urlSecond)
        PageStore.queue.async {
            tabs = .init()
            XCTAssertEqual(urlFirst, tabs.items.first?.page?.url)
            XCTAssertEqual(urlSecond, tabs.items.last?.page?.url)
            XCTAssertEqual(1, tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCurrentOutOfBounds() {
        let expect = expectation(description: "")
        PageStore.save(currentTab: 0)
        PageStore.queue.async {
            let tabs = Tabs()
            XCTAssertNil(tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testClose() {
        let expect = expectation(description: "")
        var tabs = Tabs()
        tabs.new(URL(string: "https://www.avocado.com")!)
        tabs.close(tabs.items.first!.id)
        PageStore.queue.async {
            tabs = .init()
            XCTAssertTrue(tabs.items.isEmpty)
            XCTAssertNil(tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCloseNotCurrent() {
        let expect = expectation(description: "")
        var tabs = Tabs()
        let url = URL(string: "https://www.avocado.com")!
        tabs.new(URL(string: "https://www.trees.com")!)
        tabs.new(url)
        tabs.close(tabs.items.first!.id)
        PageStore.queue.async {
            tabs = .init()
            XCTAssertEqual(url, tabs.items.first?.page?.url)
            XCTAssertEqual(1, tabs.items.count)
            XCTAssertEqual(0, tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCloseOffsetIndex() {
        let expect = expectation(description: "")
        var tabs = Tabs()
        tabs.new(URL(string: "https://www.something.com")!)
        tabs.new(URL(string: "https://www.else.com")!)
        tabs.new(URL(string: "https://www.trees.com")!)
        tabs.new(URL(string: "https://www.avocado.com")!)
        tabs.close(tabs.items.first!.id)
        PageStore.queue.async {
            tabs = .init()
            XCTAssertEqual(3, tabs.items.count)
            XCTAssertEqual(2, tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testClearIndexOnClose() {
        let expect = expectation(description: "")
        var tabs = Tabs()
        tabs.new(URL(string: "https://www.something.com")!)
        tabs.new(URL(string: "https://www.else.com")!)
        tabs.new(URL(string: "https://www.trees.com")!)
        tabs.new(URL(string: "https://www.avocado.com")!)
        tabs.close(tabs.items[3].id)
        PageStore.queue.async {
            tabs = .init()
            XCTAssertEqual(3, tabs.items.count)
            XCTAssertNil(tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCloseNoIndex() {
        let expect = expectation(description: "")
        var tabs = Tabs()
        tabs.new(URL(string: "https://www.avocado.com")!)
        tabs.new(URL(string: "https://www.trees.com")!)
        tabs.current = nil
        tabs.close(tabs.items.first!.id)
        PageStore.queue.async {
            tabs = .init()
            XCTAssertEqual(1, tabs.items.count)
            XCTAssertNil(tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testKeepIndexOnClose() {
        let expect = expectation(description: "")
        var tabs = Tabs()
        tabs.new(URL(string: "https://www.something.com")!)
        tabs.new(URL(string: "https://www.else.com")!)
        tabs.new(URL(string: "https://www.trees.com")!)
        tabs.new(URL(string: "https://www.avocado.com")!)
        tabs.current = 1
        tabs.close(tabs.items[3].id)
        PageStore.queue.async {
            tabs = .init()
            XCTAssertEqual(3, tabs.items.count)
            XCTAssertEqual(1, tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testClear() {
        let expect = expectation(description: "")
        var tabs = Tabs()
        tabs.new(URL(string: "https://www.something.com")!)
        tabs.new(URL(string: "https://www.else.com")!)
        tabs.clear()
        PageStore.queue.async {
            tabs = .init()
            XCTAssertTrue(tabs.items.isEmpty)
            XCTAssertNil(tabs.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testMaxOneWithoutPage() {
        let expect = expectation(description: "")
        let tabs = Tabs()
        tabs.new(nil)
        tabs.new(URL(string: "https://www.avocado.com")!)
        tabs.new(nil)
        tabs.new(nil)
        PageStore.queue.async {
            XCTAssertEqual(2, tabs.items.count)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testUpdatePage() {
        let expect = expectation(description: "")
        let url = URL(string: "https://www.avocado.com")!
        let title = "hello world"
        let tabs = Tabs()
        tabs.new(URL(string: "https://www.some.com")!)
        tabs.new(nil)
        tabs.update(tabs.items.last!.id, page: .init(url: url, title: title))
        PageStore.queue.async {
            XCTAssertEqual(url, tabs.items.last?.page?.url)
            XCTAssertEqual(title, tabs.items.last?.page?.title)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCloseRemoveSnapshot() {
        let expect = expectation(description: "")
        let tabs = Tabs()
        tabs.new(URL(string: "https://www.avocado.com")!)
        let id = tabs.items.first!.id
        tabs.save(.init("hello world".utf8), with: id)
        tabs.close(tabs.items.first!.id)
        tabs.image(id) {
            XCTAssertNil($0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
