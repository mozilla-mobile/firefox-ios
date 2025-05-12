// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
@testable import WebEngine

class MockPolicyDecider: WKPolicyDecider {
    var next: (any WKPolicyDecider)?

    var policyForNavigationActionCalled = 0
    var policyForNavigationResponseCalled = 0
    var policyForPopupNavigationCalled = 0

    func policyForNavigation(action: NavigationAction) -> WKPolicy {
        policyForPopupNavigationCalled += 1
        return .allow
    }
    
    func policyForNavigation(response: NavigationResponse) -> WKPolicy {
        policyForNavigationResponseCalled += 1
        return .allow
    }
    
    func policyForPopupNavigation(action: NavigationAction) -> WKPolicy {
        policyForPopupNavigationCalled += 1
        return .allow
    }
}
