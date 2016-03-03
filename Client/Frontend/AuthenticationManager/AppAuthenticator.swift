/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

class AppAuthenticator {
    static func presentAuthenticationUsingInfo(authenticationInfo: AuthenticationKeychainInfo, success: (() -> Void)?, fallback: (() -> Void)?) {
        if authenticationInfo.useTouchID {
            let localAuthContext = LAContext()
            localAuthContext.localizedFallbackTitle = AuthenticationStrings.enterPasscode
            localAuthContext.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: AuthenticationStrings.loginsTouchReason) { didSucceed, error in
                if didSucceed {
                    // Update our authentication info's last validation timestamp so we don't ask again based
                    // on the set required interval
                    authenticationInfo.recordValidation()
                    KeychainWrapper.setAuthenticationInfo(authenticationInfo)

                    dispatch_async(dispatch_get_main_queue()) {
                        success?()
                    }
                } else if let authError = error where authError.code == LAError.UserFallback.rawValue {
                    dispatch_async(dispatch_get_main_queue()) {
                        fallback?()
                    }
                }
            }
        } else {
            fallback?()
        }
    }

    static func presentPasscodeAuthentication(presentingNavController: UINavigationController?, delegate: PasscodeEntryDelegate) {
        let passcodeVC = PasscodeEntryViewController()
        passcodeVC.delegate = delegate
        let navController = UINavigationController(rootViewController: passcodeVC)
        navController.modalPresentationStyle = .FormSheet
        presentingNavController?.presentViewController(navController, animated: true, completion: nil)
    }
}