// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import LocalAuthentication
import WebKit

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
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: .AuthenticationLoginsTouchReason) { success, error in
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
            
    static func canAuthenticateDeviceOwner() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}
