/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SwiftKeychainWrapper
import MozillaAppServices

open class PushNotificationSetup {
    private var pushClient: PushClient?
    private var pushRegistration: PushRegistration?

    public func didRegister(withDeviceToken deviceToken: Data) {
        // If we've already registered this push subscription, we don't need to do it again.
        let apnsToken = deviceToken.hexEncodedString
        let keychain = KeychainWrapper.sharedAppContainerKeychain
        guard keychain.string(forKey: "apnsToken") != apnsToken else {
            return
        }

        let config = PushConfigurationLabel(rawValue: AppConstants.scheme)!.toConfiguration()
        pushClient = PushClient(endpointURL: config.endpointURL, experimentalMode: false)
        pushClient?.register(apnsToken).uponQueue(.main) { [weak self] result in
            guard let pushReg = result.successValue else { return }
            self?.pushRegistration = pushReg
            keychain.set(apnsToken, forKey: "apnsToken", withAccessibility: .afterFirstUnlock)

            let subscription = pushReg.defaultSubscription
            let devicePush = DevicePushSubscription(endpoint: subscription.endpoint.absoluteString, publicKey:  subscription.p256dhPublicKey, authKey: subscription.authKey)
            RustFirefoxAccounts.shared.accountManager.deviceConstellation()?.setDevicePushSubscription(sub: devicePush)

            keychain.set(pushReg as NSCoding, forKey: "account.push-registration", withAccessibility: .afterFirstUnlock)
        }
    }

    public func unregister() {
        if let reg = pushRegistration {
            _ = pushClient?.unregister(reg)
        }
    }
}
