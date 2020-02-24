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
        let account = Account.FirefoxAccount(
            configuration: FirefoxAccountConfigurationLabel.production.toConfiguration(prefs: profile.prefs),
            email: "testtest@test.com",
            uid: "uid",
            deviceRegistration: nil,
            declinedEngines: nil,
            stateKeyLabel: "xxx",
            state: SeparatedState(),
            deviceName: "My iPhone")

        profile.setAccount(account)

        return FxAPushMessageHandler(with: profile)
    }
}
