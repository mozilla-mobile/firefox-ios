// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

import struct MozillaAppServices.DevicePushSubscription
import struct MozillaAppServices.SubscriptionResponse

open class PushNotificationSetup {
    /// Disables FxA push notifications for the user
    public func disableNotifications() {
        if let accountManager = RustFirefoxAccounts.shared.accountManager {
            let subscriptionEndpoint = accountManager.deviceConstellation()?
                .state()?.localDevice?.pushSubscription?.endpoint
            if let subscriptionEndpoint = subscriptionEndpoint, subscriptionEndpoint.isEmpty {
                // Already disabled, lets quit early
                return
            }
            let devicePush = DevicePushSubscription(endpoint: "",
                                                    publicKey: "",
                                                    authKey: "")
            accountManager.deviceConstellation()?.setDevicePushSubscription(sub: devicePush)
        }
    }

    public func updatePushRegistration(subscriptionResponse: SubscriptionResponse) {
        let endpoint = subscriptionResponse.subscriptionInfo.endpoint
        let publicKey = subscriptionResponse.subscriptionInfo.keys.p256dh
        let authKey = subscriptionResponse.subscriptionInfo.keys.auth
        let devicePush = DevicePushSubscription(endpoint: endpoint,
                                                publicKey: publicKey,
                                                authKey: authKey)
        if let accountManager = RustFirefoxAccounts.shared.accountManager {
            let currentSubscription = accountManager.deviceConstellation()?.state()?.localDevice?.pushSubscription
            if currentSubscription == devicePush {
                return
            }
            accountManager.deviceConstellation()?.setDevicePushSubscription(sub: devicePush)
        }
    }
}
