// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class NativeErrorPageTypeTests: XCTestCase {
    func testRawValues_matchURLValues() {
        XCTAssertEqual(NativeErrorPageType.vpn.rawValue, "vpn")
        XCTAssertEqual(NativeErrorPageType.badCert.rawValue, "badCert")
        XCTAssertEqual(NativeErrorPageType.noInternet.rawValue, "noInternet")
        XCTAssertEqual(NativeErrorPageType.noResponse.rawValue, "noResponse")
        XCTAssertEqual(NativeErrorPageType.wayback.rawValue, "wayback")
        XCTAssertEqual(NativeErrorPageType.generic.rawValue, "generic")
    }
}
