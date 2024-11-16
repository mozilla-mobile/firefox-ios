// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import XCTest

class MockUserDefaultsTests: XCTestCase {
    // MARK: - Properties
    var sut: MockUserDefaults!

    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = MockUserDefaults()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: Tests
    func testMUD_whenInitialized_savedDataIsEmptyArray() {
        XCTAssertTrue(sut.savedData.isEmpty)
    }

    func testMUD_whenSavingAnItem_itExistsInSavedArray() {
        let key = "testDate"
        let date = Date()
        let expectedCount = 1

        sut.set(date, forKey: key)

        XCTAssertEqual(sut.savedData.count, expectedCount)
        XCTAssertEqual(sut.savedData[key] as? Date, date)
    }

    func testMUD_retrievingItem_itemIsDate() {
        let key = "testDate"
        let date = Date()
        sut.set(date, forKey: key)

        guard let actualObject = sut.object(forKey: key) as? Date else {
            return XCTFail("expected object is not a date")
        }

        XCTAssertEqual(actualObject, date)
    }
}
