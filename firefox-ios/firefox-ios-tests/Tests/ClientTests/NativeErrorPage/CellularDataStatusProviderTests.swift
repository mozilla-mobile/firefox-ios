// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class CellularDataStatusProviderTests: XCTestCase {
    func testIsCellularDataRestricted_returnsConsistentValueAcrossReads() {
        let provider: CellularDataStatusProviding = CTCellularDataStatusProvider()

        let first = provider.isCellularDataRestricted
        let second = provider.isCellularDataRestricted

        XCTAssertEqual(first, second)
    }
}
