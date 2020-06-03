/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
@testable import Client
import Foundation
import FxA
import SwiftyJSON
import XCTest

class FxAPushMessageTest: XCTestCase {
    func createHandler(_ profile: Profile = MockProfile()) -> FxAPushMessageHandler {
        
        return FxAPushMessageHandler(with: profile)
    }
}
