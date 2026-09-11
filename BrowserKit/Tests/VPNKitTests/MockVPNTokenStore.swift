// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import VPNKit

/// In-memory `VPNTokenStore` for tests.
final class MockVPNTokenStore: VPNTokenStore, @unchecked Sendable {
    var session: VPNDeviceSession?
    var saveError: Error?

    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0

    init(initial: VPNDeviceSession? = nil) {
        self.session = initial
    }

    func load() -> VPNDeviceSession? {
        return session
    }

    func save(_ session: VPNDeviceSession) throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        self.session = session
    }

    func clear() throws {
        clearCallCount += 1
        session = nil
    }
}
