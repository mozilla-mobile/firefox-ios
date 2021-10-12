/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

class AppAuthenticator {
    
    enum AuthenticationError: Error {
        case failedEvaluation(message: String)
        case failedAutentication(message: String)
    }
    
    static func authenticateWithDeviceOwnerAuthentication(_ completion: @escaping (Result<Void, AuthenticationError>)->()) {
        // Get a fresh context for each login. If you use the same context on multiple attempts
        //  (by commenting out the next line), then a previously successful authentication
        //  causes the next policy evaluation to succeed without testing biometry again.
        //  That's usually not what you want.
        let context = LAContext()
        
        context.localizedFallbackTitle = .AuthenticationEnterPasscode
        
        // First check if we have the needed hardware support.
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            
            let reason: String = .AuthenticationLoginsTouchReason
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
                
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(.failedAutentication(message: error?.localizedDescription ?? "Failed to authenticate")))
                }
            }
        } else {
            completion(.failure(.failedEvaluation(message: error?.localizedDescription ?? "Can't evaluate policy")))
        }
    }
    
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
        
    static func canAuthenticateDeviceOwner() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}
