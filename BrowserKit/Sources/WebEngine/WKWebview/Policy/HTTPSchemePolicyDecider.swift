// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

struct HTTPSchemePolicyDecider: WKPolicyDecider {
    var nextDecider: (any WKPolicyDecider)?

    func policyForNavigation(action: NavigationAction) -> WKPolicy {
        guard isHTTPScheme(action.request.url) else { return .cancel }
        return .allow
    }

    func policyForNavigation(response: NavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: NavigationAction) -> WKPolicy {
        guard shouldRequestBeOpenedAsPopup(action.request) else {
            return nextDecider?.policyForPopupNavigation(action: action) ?? .cancel
        }

        // We don't want to open a PayPal popup since it will result in blank screen.
        if action.sourceFrameInfo.request.url?.baseDomain == "paypal.com" {
            return .cancel
        }
        return .allow
    }

    private func isHTTPScheme(_ url: URL?) -> Bool {
        if let url, let scheme = url.scheme, ["http", "https"].contains(scheme) {
            return true
        }
        return false
    }

    private func shouldRequestBeOpenedAsPopup(_ request: URLRequest) -> Bool {
        // Treat `window.open("")` the same as `window.open("about:blank")`.
        if request.url?.absoluteString.isEmpty ?? false {
            return true
        }

        let schemesAllowedToBeOpenedAsPopups = ["http", "https", "javascript", "about"]

        if let scheme = request.url?.scheme?.lowercased(), schemesAllowedToBeOpenedAsPopups.contains(scheme) {
            return true
        }

        return false
    }
}
