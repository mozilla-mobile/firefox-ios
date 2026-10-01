// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit

/// Concrete implementation of `AppAttestKeyIDStore` that keeps the `keyID` in memory.
/// This is only used for testing since the keychain implementation is not easily testable
/// and might fail sometimes on non-signed builds on CI.
public final class MockAppAttestKeyIDStore: AppAttestKeyIDStore, @unchecked Sendable {
    private var value: String?

    public init(initial: String? = nil) {
        self.value = initial
    }

    public func loadKeyID() -> String? {
        return value
    }

    public func saveKeyID(_ keyID: String) throws {
        value = keyID
    }

    public func clearKeyID() throws {
        value = nil
    }
}
