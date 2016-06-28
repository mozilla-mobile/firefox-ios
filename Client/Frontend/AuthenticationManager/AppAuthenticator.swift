/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

class AppAuthenticator {
    static func presentAuthenticationUsingInfo(authenticationInfo: AuthenticationKeychainInfo, touchIDReason: String, success: (() -> Void)?, cancel: (() -> Void)?, fallback: (() -> Void)?) {
        let localAuthContext = LAContext()
        localAuthContext.localizedFallbackTitle = AuthenticationStrings.enterPasscode
        localAuthContext.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: touchIDReason) { didSucceed, error in
            if didSucceed {
                // Update our authentication info's last validation timestamp so we don't ask again based
                // on the set required interval
                authenticationInfo.recordValidation()
                KeychainWrapper.setAuthenticationInfo(authenticationInfo)
                dispatch_async(dispatch_get_main_queue()) {
                    success?()
                }
                return
            }

            guard let authError = error,
                      code = LAError(rawValue: authError.code) else {
                return
            }

            dispatch_async(dispatch_get_main_queue()) {
                switch code {
                case .UserFallback, .TouchIDNotEnrolled, .TouchIDNotAvailable, .TouchIDLockout:
                    fallback?()
                case .UserCancel:
                    cancel?()
                default:
                    cancel?()
                }
            }
        }
    }

    static func presentPasscodeAuthentication(presentingNavController: UINavigationController?, delegate: PasscodeEntryDelegate?) {
        let passcodeVC = PasscodeEntryViewController()
        passcodeVC.delegate = delegate
        let navController = UINavigationController(rootViewController: passcodeVC)
        navController.modalPresentationStyle = .FormSheet
        presentingNavController?.presentViewController(navController, animated: true, completion: nil)
    }
    
    static func presentPasscodeAuthentication(presentingNavController: UINavigationController?, success: (() -> Void)?, cancel: (() -> Void)?) {
        let passcodeVC = PasscodeEntryViewController()
        passcodeVC.success = success
        passcodeVC.cancel = cancel
        let navController = UINavigationController(rootViewController: passcodeVC)
        navController.modalPresentationStyle = .FormSheet
        presentingNavController?.presentViewController(navController, animated: true, completion: nil)
    }
}
