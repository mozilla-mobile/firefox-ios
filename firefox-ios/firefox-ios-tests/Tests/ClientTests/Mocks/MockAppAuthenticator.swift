// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockAppAuthenticator: AppAuthenticationProtocol {
    var authenticationState: AuthenticationState = .deviceOwnerAuthenticated
    var shouldAuthenticateDeviceOwner = true
    var shouldSucceed = true

    func getAuthenticationState(completion: @escaping (AuthenticationState) -> Void) {
        completion(authenticationState)
    }

    var canAuthenticateDeviceOwner: Bool {
        return shouldAuthenticateDeviceOwner
    }

    func authenticateWithDeviceOwnerAuthentication(_ completion: @escaping (Result<Void, AuthenticationError>) -> Void) {
        if shouldSucceed {
            completion(.success(()))
        } else {
            completion(.failure(.failedAutentication(message: "Testing mock: failure")))
        }
    }
}
