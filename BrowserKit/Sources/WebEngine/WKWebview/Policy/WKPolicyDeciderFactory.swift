// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// The root class that generates the responder chain with all the available `WKPolicyDecider`s
///
/// The class decides a `WKPolicy` for each type of navigation by asking it to it's managed chain.
class WKPolicyDeciderFactory: WKPolicyDecider {
    var next: WKPolicyDecider?

    func policyForNavigation(action: NavigationAction) -> WKPolicy {
        guard let next else { return .cancel }
        return next.policyForNavigation(action: action)
    }

    func policyForNavigation(response: NavigationResponse) -> WKPolicy {
        guard let next else { return .cancel }
        return next.policyForNavigation(response: response)
    }

    func policyForPopupNavigation(action: NavigationAction) -> WKPolicy {
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
