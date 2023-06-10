// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import MozillaAppServices

open class PushNotificationSetup {
    private var pushClient: PushClient?
    private var pushRegistration: PushRegistration?

    /// Registers the users device with the push notification server. If notificationAllowed is false the device will
    /// be unsubscribed from receiving notifications.
    /// - Parameters:
    ///   - deviceToken: A token that identifies the device to Apple Push Notification Service (APNS).
    public func didRegister(withDeviceToken deviceToken: Data) {
        let apnsToken = deviceToken.hexEncodedString
        let keychain = MZKeychainWrapper.sharedClientAppContainerKeychain

        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { accountManager in
            let subscriptionEndpoint = accountManager.deviceConstellation()?.state()?.localDevice?.pushSubscription?.endpoint
            let persistedApnsToken = keychain.string(forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock)
            // The only reason we check the existing subscription endpoint is to recover any old devices
            // that experienced https://github.com/mozilla-mobile/firefox-ios/issues/14467
            // checking the APNS token is sufficient otherwise
            if let subscriptionEndpoint = subscriptionEndpoint, !subscriptionEndpoint.isEmpty, persistedApnsToken == apnsToken {
                return
            }
            let config = LegacyPushConfigurationLabel(rawValue: AppConstants.scheme)!.toConfiguration()
            self.pushClient = PushClientImplementation(endpointURL: config.endpointURL,
                                                       experimentalMode: false)

            self.pushClient?.register(apnsToken) { [weak self] pushRegistration in
                guard let pushRegistration = pushRegistration else { return }
                self?.pushRegistration = pushRegistration

                let subscription = pushRegistration.defaultSubscription

                let endpoint = subscription.endpoint.absoluteString
                let publicKey = subscription.p256dhPublicKey
                let authKey = subscription.authKey

                let devicePush = DevicePushSubscription(endpoint: endpoint,
                                                        publicKey: publicKey,
                                                        authKey: authKey)
                accountManager.deviceConstellation()?.setDevicePushSubscription(sub: devicePush)
                // We set our apnsToken **after** the call to set the push subscription completes
                // This helps ensure that if that call fails, we will try again with a new token next time
                keychain.set(apnsToken, forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock)
                keychain.set(pushRegistration,
                             forKey: KeychainKey.fxaPushRegistration,
                             withAccessibility: .afterFirstUnlock)
            }
        }
    }

    /// Disables FxA push notifications for the user
    public func disableNotifications() {
        MZKeychainWrapper.sharedClientAppContainerKeychain.removeObject(forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock)
        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { accountManager in
            let subscriptionEndpoint = accountManager.deviceConstellation()?.state()?.localDevice?.pushSubscription?.endpoint
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
        RustFirefoxAccounts.shared.accountManager.upon { accountManager in
            let currentSubscription = accountManager.deviceConstellation()?.state()?.localDevice?.pushSubscription
            if currentSubscription == devicePush {
                return
            }
            accountManager.deviceConstellation()?.setDevicePushSubscription(sub: devicePush)
        }
    }

    public func unregister() {
        if let pushRegistration = pushRegistration {
            pushClient?.unregister(pushRegistration) {}
        }
    }
}
