// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

struct DataSchemePolicyDecider: WKPolicyDecider {
    var next: (any WKPolicyDecider)?

    func policyForPopupNavigation(action: WKNavigationAction) -> WKPolicy {
        return .allow
    }

    func policyForNavigation(action: WKNavigationAction) -> WKPolicy {
        // Only filter top-level navigation, not on data URL subframes.
        // If target frame is nil, we filter as well.
        guard action.targetFrame?.isMainFrame ?? true else {
            return .allow
        }

        return shouldAllowDataScheme(for: action.request.url) ? .allow : .cancel
    }

    func policyForNavigation(response: WKNavigationResponse) -> WKPolicy {
        return .allow
    }

    func shouldAllowDataScheme(for url: URL?) -> Bool {
        guard let url else { return false }
        let urlString = url.absoluteString.lowercased()

        // Allow certain image types
        if urlString.hasPrefix("data:image/") && !urlString.hasPrefix("data:image/svg+xml") {
            return true
        }

        // Allow video, and certain application types
        if urlString.hasPrefix("data:video/")
            || urlString.hasPrefix("data:application/pdf")
            || urlString.hasPrefix("data:application/json") {
            return true
        }

        // Allow plain text types.
        // Note the format of data URLs is `data:[<media type>][;base64],<data>`
        // with empty <media type> indicating plain text.
        if urlString.hasPrefix("data:;base64,")
            || urlString.hasPrefix("data:,")
            || urlString.hasPrefix("data:text/plain,")
            || urlString.hasPrefix("data:text/plain;") {
            return true
        }

        return false
    }
}
