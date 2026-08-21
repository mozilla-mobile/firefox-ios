// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class CellularDataStatusProviderTests: XCTestCase {
    func testShared_returnsSameInstance() {
        let first = CTCellularDataStatusProvider.shared
        let second = CTCellularDataStatusProvider.shared

        XCTAssertTrue(first === second)
    }

    func testIsCellularDataRestricted_doesNotCrash() {
        let provider: CellularDataStatusProviding = CTCellularDataStatusProvider.shared

        let first = provider.isCellularDataRestricted
        let second = provider.isCellularDataRestricted

        XCTAssertEqual(first, second)
    }

    func testUpdateCachedState_updatesCachedValueForNextRead() {
        let provider = CTCellularDataStatusProvider.shared

        provider.updateCachedState(.restricted)
        XCTAssertTrue(provider.isCellularDataRestricted)

        provider.updateCachedState(.notRestricted)
        XCTAssertFalse(provider.isCellularDataRestricted)
    }
}
