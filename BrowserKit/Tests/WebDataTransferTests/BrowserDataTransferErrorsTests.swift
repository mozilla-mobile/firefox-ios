// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebDataTransfer

final class BrowserDataTransferErrorsTests: XCTestCase {
    func testFailureReason_cancellationHasNoReason() {
        XCTAssertNil(BrowserDataTransferErrors.failureReason(for: CancellationError()))
    }

    func testFailureReason_frameworkErrorsAreUnknown() {
        let frameworkError = NSError(domain: "BEBrowserDataExchangeErrorDomain", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "https://example.com secret"
        ])

        XCTAssertEqual(BrowserDataTransferErrors.failureReason(for: frameworkError), .unknown)
        XCTAssertEqual(BrowserDataTransferErrors.failureReason(for: URLError(.notConnectedToInternet)), .unknown)
    }
}
