// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import MozillaAppServices

class PasswordManagerSelectionHelperTests: XCTestCase {
    private var selectionHelper: PasswordManagerSelectionHelper!
    private let loginRecord = EncryptedLogin(
        credentials: URLCredential(
            user: "test",
            password: "doubletest",
            persistence: .permanent
        ),
        protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
    )

    override func setUp() {
        super.setUp()
        selectionHelper = PasswordManagerSelectionHelper()
    }

    override func tearDown() {
        selectionHelper = nil
        super.tearDown()
    }

    func testSelectCellFromLoginRecord() {
        XCTAssertEqual(selectionHelper.numberOfSelectedCells, 0)

        selectionHelper.setCellSelected(with: loginRecord)
        XCTAssertEqual(selectionHelper.numberOfSelectedCells, 1)
    }

    func testAddTwoTimesTheSameLoginRecordGivesOneSelection() {
        selectionHelper.setCellSelected(with: loginRecord)
        selectionHelper.setCellSelected(with: loginRecord)

        XCTAssertEqual(selectionHelper.numberOfSelectedCells, 1)
    }

    func testCellSelectionStateIsTrueWhenLoginRecordIsAddedToSelcted() {
        XCTAssertFalse(selectionHelper.isCellSelected(with: loginRecord))

        selectionHelper.setCellSelected(with: loginRecord)
        XCTAssertTrue(selectionHelper.isCellSelected(with: loginRecord))
    }

    func testRemoveCell() {
        selectionHelper.setCellSelected(with: loginRecord)
        XCTAssertEqual(selectionHelper.numberOfSelectedCells, 1)

        selectionHelper.removeCell(with: loginRecord)
        XCTAssertEqual(selectionHelper.numberOfSelectedCells, 0)
    }

    func testRemoveAllCell() {
        let loginRecord2 = EncryptedLogin(
            credentials: URLCredential(user: "filippo", password: "testtest", persistence: .permanent),
            protectionSpace: URLProtectionSpace.fromOrigin("https://testtest.com")
        )

        selectionHelper.setCellSelected(with: loginRecord)
        selectionHelper.setCellSelected(with: loginRecord2)
        XCTAssertEqual(selectionHelper.numberOfSelectedCells, 2)

        selectionHelper.removeAllCells()
        XCTAssertEqual(selectionHelper.numberOfSelectedCells, 0)
    }
}
