// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

struct HTTPSchemePolicyDecider: WKPolicyDecider {
    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        guard isHTTPScheme(action.request.url) else { return .cancel }
        return .allow
    }

    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        return .allow
    }

    private func isHTTPScheme(_ url: URL?) -> Bool {
        if let url, let scheme = url.scheme, ["http", "https"].contains(scheme) {
            return true
        }
        return false
    }
}

struct AppLaunchPolicyDecider: WKPolicyDecider {
    // We should add marketplace kit schemes
    // Should we consider doing like for popup to check if we can open the app trough the application and just
    // open the app in that case ?
    private let supportedSchemes = ["sms", "tel", "facetime", "facetime-audio", "itms-apps", "itms-appss"]
    private let appStoreHosts = ["itunes.apple.com", "apps.apple.com", "appsto.re"]

    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        guard let url = action.request.url else { return .cancel }
        if isSupportedHost(url) || isSupportedScheme(url) {
            return .openApp(url: url)
        }
        return .allow
    }
    
    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        return .allow
    }

    private func isSupportedHost(_ url: URL) -> Bool {
        guard let host = url.host, let scheme = url.scheme else { return false }
        return appStoreHosts.contains(host) && ["http", "https"].contains(scheme)
    }

    private func isSupportedScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        return supportedSchemes.contains(scheme)
    }
}

struct DeeplinkPolicyDecider: WKPolicyDecider {
    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        return .allow
    }

    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        return .allow
    }
}
