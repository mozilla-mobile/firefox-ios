/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Storage
import Shared

/*
 * A base test type for tests that need a profile.
 */
class ProfileTest: XCTestCase {
    func withTestProfile(callback: (profile: Profile) -> Void) {
        callback(profile: MockProfile())
    }
}
