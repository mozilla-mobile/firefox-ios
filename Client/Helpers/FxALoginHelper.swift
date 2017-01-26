/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Deferred
import Foundation
import Shared

/// This class manages the from successful login for FxAccounts to 
/// asking the user for notification permissions, registering for 
/// remote push notifications (APNS), registering for WebPush notifcations
/// then creating an account and storing it in the profile.
public class FxALoginHelper {
    private let deferred = Success()

    private let pushClient: PushClient

    private weak var application: UIApplication?
    private weak var profile: BrowserProfile?

    public init(application: UIApplication, profile: BrowserProfile) {
        let configuration = StagePushConfiguration()
        let client = PushClient(endpointURL: configuration.endpointURL)

        self.application = application
        self.pushClient = client
        self.profile = profile
    }

    public func userDidLogin() -> Success {
        return deferred
    }

    public func userDidAcceptUserNotifications() {
        
    }

    public func userDidRejectUserNotifications() {

    }

    public func apnsRegisterDidSucceed(apnsToken apnsToken: String) {
        pushClient.register(apnsToken).upon { res in
            if let pushRegistration = res.successValue {
                return self.pushRegistrationDidSucceed(apnsToken: apnsToken, pushRegistration: pushRegistration)
            }
            self.apnsRegisterDidFail()
        }
    }

    public func apnsRegisterDidFail() {

    }

    public func pushRegistrationDidSucceed(apnsToken apnsToken: String, pushRegistration: PushRegistration) {

    }

    public func pushRegistrationDidFail() {

    }


}
