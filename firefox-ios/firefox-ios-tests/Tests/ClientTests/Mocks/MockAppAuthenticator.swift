// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
@testable import Client

class MockAppAuthenticator: AppAuthenticationProtocol, @unchecked Sendable {
    var authenticationState: AuthenticationState = .deviceOwnerAuthenticated
    var shouldAuthenticateDeviceOwner = true
    var shouldSucceed = true

    func getAuthenticationState(completion: @MainActor @escaping @Sendable (AuthenticationState) -> Void) {
        ensureMainThread {
            completion(self.authenticationState)
        }
    }

    var canAuthenticateDeviceOwner: Bool {
        return shouldAuthenticateDeviceOwner
    }

    func authenticateWithDeviceOwnerAuthentication(
        _ completion: @MainActor @escaping @Sendable (Result<Void, AuthenticationError>) -> Void
    ) {
        ensureMainThread {
            if self.shouldSucceed {
                completion(.success(()))
            } else {
                completion(.failure(.failedAuthentication(message: "Testing mock: failure")))
            }
        }
    }
}
