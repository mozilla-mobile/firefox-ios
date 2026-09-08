// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
@testable import IPProtectionKit

final class MockIPProtectionSessionRefresher: IPProtectionSessionRefreshing, @unchecked Sendable {
    private let tokenStore: IPProtectionTokenStore
    var sessionToReturn: IPProtectionDeviceSession?
    var refreshError: Error?

    private(set) var refreshCallCount = 0
    private(set) var lastAssertion: AssertionResult?

    init(tokenStore: IPProtectionTokenStore, sessionToReturn: IPProtectionDeviceSession? = nil) {
        self.tokenStore = tokenStore
        self.sessionToReturn = sessionToReturn
    }

    func refreshSession(assertion: AssertionResult) async throws {
        refreshCallCount += 1
        lastAssertion = assertion
        if let refreshError { throw refreshError }
        if let sessionToReturn { try tokenStore.save(sessionToReturn) }
    }
}
