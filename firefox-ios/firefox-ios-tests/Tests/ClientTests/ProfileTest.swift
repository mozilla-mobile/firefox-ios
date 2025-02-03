// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
@testable import Account
import Foundation
import Shared
import Storage

import XCTest

/*
 * A base test type for tests that need a profile.
 */

class ProfileTest: XCTestCase {
    var profile: MockProfile?

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Setup mock profile 
        profile = MockProfile(databasePrefix: "profile-test")
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    func withTestProfile(_ callback: (_ profile: Client.Profile) -> Void) {
        guard let mockProfile = profile else { return }
        mockProfile.reopen()
        callback(mockProfile)
        mockProfile.shutdown()
    }
}
