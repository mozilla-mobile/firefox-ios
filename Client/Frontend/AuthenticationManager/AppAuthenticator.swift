/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

class AppAuthenticator {
    static func presentAuthenticationUsingInfo(_ authenticationInfo: AuthenticationKeychainInfo, touchIDReason: String, success: (() -> Void)?, cancel: (() -> Void)?, fallback: (() -> Void)?) {
        if authenticationInfo.useTouchID {
            let localAuthContext = LAContext()
            localAuthContext.localizedFallbackTitle = .AuthenticationEnterPasscode
            localAuthContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: touchIDReason) { didSucceed, error in
                if didSucceed {
                    // Update our authentication info's last validation timestamp so we don't ask again based
                    // on the set required interval
                    authenticationInfo.recordValidation()
                    KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authenticationInfo)
                    DispatchQueue.main.async {
                        success?()
                    }
                    return
                }

                guard let authError = error else {
                    return
                }

                DispatchQueue.main.async {
                    switch Int32(authError._code) {
                    case kLAErrorUserFallback,
                         kLAErrorBiometryNotEnrolled,
                         kLAErrorBiometryNotAvailable,
                         kLAErrorBiometryLockout:
                        fallback?()
                    case kLAErrorUserCancel:
                        cancel?()
                    default:
                        cancel?()
                    }
                }
            }
        } else {
            fallback?()
        }
    }

    static func presentPasscodeAuthentication(_ presentingNavController: UINavigationController?) -> Deferred<Bool> {
        let deferred = Deferred<Bool>()
        let passcodeVC = PasscodeEntryViewController(passcodeCompletion: { isOk in
            deferred.fill(isOk)
        })

        let navController = UINavigationController(rootViewController: passcodeVC)
        navController.modalPresentationStyle = .formSheet
        presentingNavController?.present(navController, animated: true, completion: nil)
        return deferred
    }
}
