// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LocalAuthentication
import WebKit

enum AuthenticationError: Error {
    case failedEvaluation(message: String)
    case failedAutentication(message: String)
}

protocol AppAuthenticationProtocol {
    func authenticateWithDeviceOwnerAuthentication(_ completion: @escaping (Result<Void, AuthenticationError>) -> Void)
    func canAuthenticateDeviceOwner() -> Bool
}

class AppAuthenticator: AppAuthenticationProtocol {
    func authenticateWithDeviceOwnerAuthentication(_ completion: @escaping (Result<Void, AuthenticationError>) -> Void) {
        // Get a fresh context for each login. If you use the same context on multiple attempts
        //  (by commenting out the next line), then a previously successful authentication
        //  causes the next policy evaluation to succeed without testing biometry again.
        //  That's usually not what you want.
        let context = LAContext()

        // First check if we have the needed hardware support.
        var error: NSError?
        let localizedErrorMessage = String.Biometry.Screen.UniversalAuthenticationReason
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localizedErrorMessage) { success, error in
                if success {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.failedAutentication(message: error?.localizedDescription ?? "Failed to authenticate")))
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(.failure(.failedEvaluation(message: error?.localizedDescription ?? "Can't evaluate policy")))
            }
        }
    }

    func canAuthenticateDeviceOwner() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}
