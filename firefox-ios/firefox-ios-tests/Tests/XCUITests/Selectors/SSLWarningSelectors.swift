// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SSLWarningSelectorsSet {
    var WARNING_MESSAGE: Selector { get }
    var GO_BACK_BUTTON: Selector { get }
    var ADVANCED_BUTTON: Selector { get }
    var VISIT_SITE_ANYWAY_LINK: Selector { get }
    var PAGE_DOMAIN: Selector { get }
    var all: [Selector] { get }
}

struct SSLWarningSelectors: SSLWarningSelectorsSet {
    private enum IDs {
        static let warningText = "This Connection is Untrusted"
        static let goBack = "Go Back"
        static let advanced = "Advanced"
        static let visitSiteAnyway = "Visit site anyway"
        static let domain = "expired.badssl.com"
    }

    let WARNING_MESSAGE = Selector.webViewOtherByLabel(
        IDs.warningText,
        description: "SSL warning message shown inside webView",
        groups: ["browser", "ssl"]
    )

    let GO_BACK_BUTTON = Selector.buttonByLabel(
        IDs.goBack,
        description: "Go Back button in SSL warning screen",
        groups: ["browser", "ssl"]
    )

    let ADVANCED_BUTTON = Selector.buttonByLabel(
        IDs.advanced,
        description: "Advanced button in SSL warning screen",
        groups: ["browser", "ssl"]
    )

    let VISIT_SITE_ANYWAY_LINK = Selector.linkById(
        IDs.visitSiteAnyway,
        description: "Visit site anyway link in SSL warning screen",
        groups: ["browser", "ssl"]
    )

    let PAGE_DOMAIN = Selector.anyId(
        IDs.domain,
        description: "Domain element after bypassing SSL warning",
        groups: ["browser", "ssl"]
    )

    var all: [Selector] {
        [WARNING_MESSAGE, GO_BACK_BUTTON, ADVANCED_BUTTON, VISIT_SITE_ANYWAY_LINK, PAGE_DOMAIN]
    }
}
