// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockAppAuthenticator: AppAuthenticationProtocol {
    var shouldAuthenticateDeviceOwner = true
    func canAuthenticateDeviceOwner() -> Bool {
        return shouldAuthenticateDeviceOwner
    }

    var shouldSucceed = true
    func authenticateWithDeviceOwnerAuthentication(_ completion: @escaping (Result<Void, AuthenticationError>) -> Void) {
        if shouldSucceed {
            completion(.success(()))
        } else {
            completion(.failure(.failedAutentication(message: "Testing mock: failure")))
        }
    }
}
