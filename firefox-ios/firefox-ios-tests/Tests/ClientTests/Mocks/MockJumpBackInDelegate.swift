// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class MockJumpBackInDelegate: JumpBackInDelegate {
    private var continuation: CheckedContinuation<Void, Never>?
    var didLoadNewDataCount = 0
    
    func didLoadNewData() {
        didLoadNewDataCount += 1
        continuation?.resume()
        continuation = nil
    }

    func waitForNewData() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}
