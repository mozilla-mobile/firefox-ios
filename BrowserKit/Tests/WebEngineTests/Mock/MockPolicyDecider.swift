// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
@testable import WebEngine

class MockPolicyDecider: WKPolicyDecider {
    var nextDecider: (any WKPolicyDecider)?

    var policyForNavigationActionCalled = 0
    var policyForNavigationResponseCalled = 0
    var policyForPopupNavigationCalled = 0
    var policyToReturn: WKPolicy = .allow

    func policyForNavigation(action: NavigationAction) -> WKPolicy {
        policyForNavigationActionCalled += 1
        return policyToReturn
    }

    func policyForNavigation(response: NavigationResponse) -> WKPolicy {
        policyForNavigationResponseCalled += 1
        return policyToReturn
    }

    func policyForPopupNavigation(action: NavigationAction) -> WKPolicy {
        policyForPopupNavigationCalled += 1
        return policyToReturn
    }
}
