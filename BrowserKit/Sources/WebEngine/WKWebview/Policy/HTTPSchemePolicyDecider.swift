// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

struct HTTPSchemePolicyDecider: WKPolicyDecider {
    var next: (any WKPolicyDecider)?

    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        guard isHTTPScheme(action.request.url) else { return .cancel }
        return .allow
    }

    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        guard shouldRequestBeOpenedAsPopup(action.request) else {
            return next?.policyForPopupNavigation(action: action) ?? .cancel
        }

        // Check if we want to open 
        if action.sourceFrame.request.url?.baseDomain == "paypal.com" {
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

        /// List of schemes that are allowed to be opened in new tabs.
        let schemesAllowedToBeOpenedAsPopups = ["http", "https", "javascript", "data", "about"]

        if let scheme = request.url?.scheme?.lowercased(), schemesAllowedToBeOpenedAsPopups.contains(scheme) {
            return true
        }

        return false
    }
}

struct AppLaunchPolicyDecider: WKPolicyDecider {
    var next: (any WKPolicyDecider)?

    // We should add marketplace kit schemes
    // Should we consider doing like for popup to check if we can open the app trough the application and just
    // open the app in that case ?
    private let supportedSchemes = ["sms", "tel", "facetime", "facetime-audio", "itms-apps", "itms-appss", "whatsapp"]
    private let appStoreHosts = ["itunes.apple.com", "apps.apple.com", "appsto.re"]

    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        guard let url = action.request.url else { return .cancel }
        if isSupportedHost(url) || isSupportedScheme(url) {
            return .openApp
        }
        return .cancel
    }
    
    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        guard let url = action.request.url,
              (isSupportedHost(url) || isSupportedScheme(url)) else {
            return next?.policyForPopupNavigation(action: action) ?? .cancel
        }

        return .openApp
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

struct LocalRequestPolicyDecider: WKPolicyDecider {
    var next: (any WKPolicyDecider)?
    
    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        return .allow
    }
    
    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        guard isRequestInternalPrivileged(action.request) else {
            return next?.policyForPopupNavigation(action: action) ?? .cancel
        }
        return .allow
    }

    private func isRequestInternalPrivileged(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return true }

        if let url = WKInternalURL(url) {
            return !url.isAuthorized
        }
        return false
    }
}

struct DeeplinkPolicyDecider: WKPolicyDecider {
    var next: (any WKPolicyDecider)?

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
