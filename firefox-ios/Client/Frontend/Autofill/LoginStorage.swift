// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

import struct MozillaAppServices.Login

protocol LoginStorage {
    func listLogins() async throws -> [Login]
}

extension RustLogins: LoginStorage {
    func listLogins() async throws -> [Login] {
        return try await withCheckedThrowingContinuation { continuation in
            self.listLogins().upon { result in
                switch result {
                case .success(let logins):
                    continuation.resume(returning: logins)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

class MockLoginStorage: LoginStorage {
    var shouldThrowError = false
    func listLogins() async throws -> [Login] {
        if shouldThrowError {
            struct StorageError: Error {}
            throw StorageError()
        } else {
            // Simulate a delay to fetch logins
            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC) // 0.5 seconds

            // Return mock login data
            let mockLogins: [Login] = [
                Login(
                    credentials: URLCredential(
                        user: "test",
                        password: "doubletest",
                        persistence: .permanent
                    ),
                    protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
                ),
                Login(
                    credentials: URLCredential(
                        user: "test",
                        password: "doubletest",
                        persistence: .permanent
                    ),
                    protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
                )
            ]

            return mockLogins
        }
    }
}
