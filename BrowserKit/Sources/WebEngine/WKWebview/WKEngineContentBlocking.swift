// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

enum WKContentBlocklistFileName: String, CaseIterable {
    case advertisingURLs = "disconnect-block-advertising"
    case analyticsURLs = "disconnect-block-analytics"
    case socialURLs = "disconnect-block-social"
    case cryptomining = "disconnect-block-cryptomining"
    case fingerprinting = "disconnect-block-fingerprinting"
    case advertisingCookies = "disconnect-block-cookies-advertising"
    case analyticsCookies = "disconnect-block-cookies-analytics"
    case socialCookies = "disconnect-block-cookies-social"

    static var standardSet: [WKContentBlocklistFileName] {
        return [
            .advertisingCookies,
            .analyticsCookies,
            .socialCookies,
            .cryptomining,
            .fingerprinting
        ]
    }

    static var strictSet: [WKContentBlocklistFileName] {
        return [
            .advertisingURLs,
            .analyticsURLs,
            .socialURLs,
            cryptomining,
            fingerprinting
        ]
    }
}

struct WKNoImageModeDefaults {
    static let Script = "[{'trigger':{'url-filter':'.*','resource-type':['image']},'action':{'type':'block'}}]"
        .replacingOccurrences(of: "'", with: "\"")
    static let ScriptName = "images"
}

class WKContentBlocker {
    private let ruleStore = WKContentRuleListStore.default()
    private var blockImagesRule: WKContentRuleList?

    init(blockImagesRule: WKContentRuleList? = nil) {
        ruleStore?.compileContentRuleList(
            forIdentifier: WKNoImageModeDefaults.ScriptName,
            encodedContentRuleList: WKNoImageModeDefaults.Script) { rule, error in
                guard error == nil, rule != nil else { return }
                self.blockImagesRule = rule
            }

        // TODO: Read safelist during startup
        // TODO: Clean up and remove old blocker file lists based on date and name, if newer available
    }
}
