// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

class MockSummarizeToSAcceptor: SummarizeToSAcceptor {
    var acceptTosConsentCalled = 0
    var denyTosConsentCalled = 0

    func acceptTosConsent() {
        acceptTosConsentCalled += 1
    }

    func denyTosConsent() {
        denyTosConsentCalled += 1
    }
}
