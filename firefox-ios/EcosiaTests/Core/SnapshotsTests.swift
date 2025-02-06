// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class SnapshotsTests: XCTestCase {
    private var tabs: Tabs!

    override func setUp() {
        tabs = .init()
        try? FileManager.default.removeItem(at: FileManager.snapshots)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.snapshots)
    }

    func testNoImage() {
        let expect = expectation(description: "")
        tabs.image(UUID()) {
            XCTAssertNil($0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testGetImage() {
        let expect = expectation(description: "")
        let id = UUID()
        tabs.save(.init("hello world".utf8), with: id)
        tabs.queue.async {
            self.tabs.image(UUID()) {
                XCTAssertNil($0)
            }
            self.tabs.image(id) {
                XCTAssertEqual("hello world", String(decoding: $0 ?? Data(), as: UTF8.self))
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testReplaceImage() {
        let expect = expectation(description: "")
        let id = UUID()
        tabs.save(.init("hello world".utf8), with: id)
        tabs.save(.init("lorem ipsum".utf8), with: id)
        tabs.queue.async {
            self.tabs.image(id) {
                XCTAssertEqual("lorem ipsum", String(decoding: $0 ?? Data(), as: UTF8.self))
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testClear() {
        let expect = expectation(description: "")
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()
        tabs.save(.init("hello world".utf8), with: idA)
        tabs.save(.init("lorem ipsum".utf8), with: idB)
        tabs.save(.init("avocado".utf8), with: idC)
        tabs.queue.async {
            self.tabs.image(idA) {
                XCTAssertNotNil($0)
                self.tabs.clear()
                self.tabs.image(idA) {
                    XCTAssertNil($0)
                    expect.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testDelete() {
        let expect = expectation(description: "")
        let idA = UUID()
        let idB = UUID()
        tabs.save(.init("hello world".utf8), with: idA)
        tabs.save(.init("lorem ipsum".utf8), with: idB)
        tabs.deleteSnapshot(idA)
        tabs.queue.async {
            self.tabs.image(idA) {
                XCTAssertNil($0)
            }
            self.tabs.image(idB) {
                XCTAssertNotNil($0)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
}
