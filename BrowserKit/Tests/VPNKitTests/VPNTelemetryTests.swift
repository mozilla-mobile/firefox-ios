// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import XCTest

@testable import VPNKit

final class VPNAttestationFailureReasonTests: XCTestCase {
    func test_init_neverForwardsTheResponseBody() {
        let htmlPage = AppAttestServiceError.serverError(
            statusCode: 502,
            description: "<html><body>secret-key-id-12345</body></html>"
        )

        XCTAssertEqual(VPNAttestationFailureReason(htmlPage), .unknown)
    }
}
