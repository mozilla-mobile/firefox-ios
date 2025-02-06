// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class FavouritesTests: XCTestCase {

    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.pages)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.pages)
    }

    func testSave() {
        let expect = expectation(description: "")
        let favourites = Favourites()
        favourites.items.append(.init(url: URL(string: "https://avocado.com")!, title: ""))
        PageStore.queue.async {
            XCTAssertTrue(FileManager.default.fileExists(atPath: FileManager.favourites.path))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testLoad() {
        let expect = expectation(description: "")
        var favourites = Favourites()
        favourites.items.append(.init(url: URL(string: "https://www.avocado.com")!, title: "hello world"))
        favourites.items.append(.init(url: URL(string: "https://www.guacamole.com")!, title: "lorem ipsum"))
        PageStore.queue.async {
            favourites = .init()
            XCTAssertEqual("hello world", favourites.items.first?.title)
            XCTAssertEqual("lorem ipsum", favourites.items.last?.title)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
