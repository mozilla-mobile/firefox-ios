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
    ///   - notificationAllowed: Indicates if the user allowed sync push notification in the settings.
    public func didRegister(withDeviceToken deviceToken: Data, notificationAllowed: Bool) {
        // If we've already registered this push subscription, we don't need to do it again.
        let apnsToken = deviceToken.hexEncodedString
        let keychain = MZKeychainWrapper.sharedClientAppContainerKeychain
        guard keychain.string(forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock) != apnsToken
        else { return }

        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { accountManager in
            let config = PushConfigurationLabel(rawValue: AppConstants.scheme)!.toConfiguration()
            self.pushClient = PushClientImplementation(endpointURL: config.endpointURL,
                                                       experimentalMode: false)

            self.pushClient?.register(apnsToken) { [weak self] pushRegistration in
                guard let pushRegistration = pushRegistration else { return }
                self?.pushRegistration = pushRegistration

                let subscription = pushRegistration.defaultSubscription

                // send empty parameters for push subscription if no notifications should be send to device
                let endpoint = notificationAllowed ? subscription.endpoint.absoluteString : ""
                let publicKey = notificationAllowed ? subscription.p256dhPublicKey : ""
                let authKey = notificationAllowed ? subscription.authKey : ""

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

    public func unregister() {
        if let pushRegistration = pushRegistration {
            pushClient?.unregister(pushRegistration) {}
        }
    }
}
