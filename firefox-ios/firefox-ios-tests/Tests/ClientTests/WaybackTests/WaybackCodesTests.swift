// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class WaybackCodesTests: XCTestCase {
    func test_isWaybackCode_returnsTrueForEligibleCodes() {
        XCTAssertTrue(WaybackCodes.isWaybackCode(Int(CFNetworkErrors.cfurlErrorTimedOut.rawValue)))
        XCTAssertTrue(WaybackCodes.isWaybackCode(Int(CFNetworkErrors.cfurlErrorCannotFindHost.rawValue)))
        XCTAssertTrue(WaybackCodes.isWaybackCode(Int(CFNetworkErrors.cfurlErrorCannotConnectToHost.rawValue)))
        XCTAssertTrue(WaybackCodes.isWaybackCode(Int(CFNetworkErrors.cfurlErrorDNSLookupFailed.rawValue)))
        XCTAssertTrue(WaybackCodes.isWaybackCode(Int(CFNetworkErrors.cfurlErrorResourceUnavailable.rawValue)))
    }

    func test_isWaybackCode_returnsFalseForIneligibleCodes() {
        XCTAssertFalse(WaybackCodes.isWaybackCode(Int(CFNetworkErrors.cfurlErrorCancelled.rawValue)))
        XCTAssertFalse(WaybackCodes.isWaybackCode(NSURLErrorServerCertificateUntrusted))
        XCTAssertFalse(WaybackCodes.isWaybackCode(NSURLErrorServerCertificateHasBadDate))
    }

    func test_isWaybackCode_returnsFalseForCodeOutOfInt32Range() {
        XCTAssertFalse(WaybackCodes.isWaybackCode(Int.max))
    }

    func test_isWaybackCode_returnsFalseForUnrecognizedCode() {
        XCTAssertFalse(WaybackCodes.isWaybackCode(0))
    }
}
