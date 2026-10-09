// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import VPNKit

/// In-memory `VPNProxyTokenFetching` for tests.
final class MockVPNProxyTokenFetching: VPNProxyTokenFetching, @unchecked Sendable {
    var tokenToReturn: VPNProxyToken
    var fetchError: Error?

    private(set) var fetchCallCount = 0

    init(tokenToReturn: VPNProxyToken) {
        self.tokenToReturn = tokenToReturn
    }

    func fetchProxyToken() async throws -> VPNProxyToken {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return tokenToReturn
    }
}
