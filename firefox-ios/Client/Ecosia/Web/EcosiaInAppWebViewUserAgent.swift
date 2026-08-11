// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

/// User agent used by in-app web views that should identify as the Ecosia iOS browser.
enum EcosiaInAppWebViewUserAgent {
    static func mobileUserAgent() -> String {
        UserAgentBuilder.defaultMobileUserAgent().userAgent()
    }
}
