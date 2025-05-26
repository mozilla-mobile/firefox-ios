// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

enum SupportedAppScheme: String, CaseIterable {
    case sms, tel, facetime, whatsapp
    case facetimeAudio = "facetime-audio"
    case appstore = "itms-apps"
}

struct AppLaunchPolicyDecider: WKPolicyDecider {
    var nextDecider: (any WKPolicyDecider)?

    // TODO: - FXIOS-11259 - add market place kit
    private let supportedSchemes = SupportedAppScheme.allCases
    private let appStoreHosts = ["itunes.apple.com", "apps.apple.com", "appsto.re"]

    func policyForNavigation(action: NavigationAction) -> WKPolicy {
        guard let url = action.request.url else { return .cancel }
        if isSupportedHost(url) || isSupportedScheme(url) {
            return .launchExternalApp
        }
        return .cancel
    }

    func policyForNavigation(response: NavigationResponse) -> WKPolicy {
        return .allow
    }

    func policyForPopupNavigation(action: NavigationAction) -> WKPolicy {
        guard let url = action.request.url,
              isSupportedHost(url) || isSupportedScheme(url) else {
            return nextDecider?.policyForPopupNavigation(action: action) ?? .cancel
        }

        return .launchExternalApp
    }

    private func isSupportedHost(_ url: URL) -> Bool {
        guard let host = url.host, let scheme = url.scheme else { return false }
        return appStoreHosts.contains(host) && ["http", "https"].contains(scheme)
    }

    private func isSupportedScheme(_ url: URL) -> Bool {
        guard let rawScheme = url.scheme,
              let scheme = SupportedAppScheme(rawValue: rawScheme) else { return false }
        return supportedSchemes.contains(scheme)
    }
}
