// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

struct LocalRequestPolicyDecider: WKPolicyDecider {
    var nextDecider: (any WKPolicyDecider)?

    func policyForNavigation(action: NavigationAction) -> WKPolicy {
        return .allow
    }

    func policyForNavigation(response: NavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: NavigationAction) -> WKPolicy {
        guard isRequestInternalPrivileged(action.request) else {
            return nextDecider?.policyForPopupNavigation(action: action) ?? .cancel
        }
        return .allow
    }

    private func isRequestInternalPrivileged(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return true }

        if let url = WKInternalURL(url) {
            return url.isAuthorized
        }
        return false
    }
}
