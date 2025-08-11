// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

class MerinoProviderTests: XCTestCase {
    func testIncorrectLocalesAreNotSupported() {
        XCTAssertFalse(MerinoProvider.islocaleSupported("en_BD"))
        XCTAssertFalse(MerinoProvider.islocaleSupported("enCA"))
    }

    func testCorrectLocalesAreSupported() {
        XCTAssertTrue(MerinoProvider.islocaleSupported("en_US"))
        XCTAssertTrue(MerinoProvider.islocaleSupported("en_GB"))
        XCTAssertTrue(MerinoProvider.islocaleSupported("en_CA"))
    }
}
