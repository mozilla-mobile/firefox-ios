// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

class WKPolicyDeciderFactory: WKPolicyDecider {
    var next: WKPolicyDecider?

    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        guard let next else { return .cancel }
        return next.policyForNavigation(action: action)
    }
    
    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        guard let next else { return .cancel }
        return next.policyForNavigation(response: response)
    }
    
    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        next = popupNavigationResponderChain()
        guard let next else { return .cancel }
        return next.policyForPopupNavigation(action: action)
    }

    private func popupNavigationResponderChain() -> WKPolicyDecider? {
        let appLaunch = AppLaunchPolicyDecider()
        let data = DataSchemePolicyDecider(next: appLaunch)
        let http = HTTPSchemePolicyDecider(next: data)
        let local = LocalRequestPolicyDecider(next: http)
        return local
    }
}
