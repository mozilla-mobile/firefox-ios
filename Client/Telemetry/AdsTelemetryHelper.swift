// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import WebKit
import Glean

public enum BasicSearchProvider: String {
    case google
    case duckduckgo
    case yahoo
    case bing
}

public struct SearchProviderModel {
    typealias Predicate = (String) -> Bool
    let name: String
    let regexp: String
    let queryParam: String
    let codeParam: String
    let codePrefixes: [String]
    let followOnParams: [String]
    let extraAdServersRegexps: [String]
    
    public static let searchProviderList = [
        SearchProviderModel(
            name: BasicSearchProvider.google.rawValue,
            regexp: #"^https:\/\/www\.google\.(?:.+)\/search"#,
            queryParam: "q",
            codeParam: "client",
            codePrefixes: ["firefox"],
            followOnParams: ["oq", "ved", "ei"],
            extraAdServersRegexps: [
                #"^https?:\/\/www\.google(?:adservices)?\.com\/(?:pagead\/)?aclk"#,
                #"^(http|https):\/\/clickserve.dartsearch.net\/link\/"#
            ]
        ),
        SearchProviderModel(
            name: BasicSearchProvider.duckduckgo.rawValue,
            regexp: #"^https:\/\/duckduckgo\.com\/"#,
            queryParam: "q",
            codeParam: "t",
            codePrefixes: ["f"],
            followOnParams: [],
            extraAdServersRegexps: [
                #"^https:\/\/duckduckgo.com\/y\.js"#,
                #"^https:\/\/www\.amazon\.(?:[a-z.]{2,24}).*(?:tag=duckduckgo-)"#
            ]
        ),
        // Note: Yahoo shows ads from bing and google
        SearchProviderModel(
            name: BasicSearchProvider.yahoo.rawValue,
            regexp: #"^https:\/\/(?:.*)search\.yahoo\.com\/search"#,
            queryParam: "p",
            codeParam: "",
            codePrefixes: [],
            followOnParams: [],
            extraAdServersRegexps: [#"^(http|https):\/\/clickserve.dartsearch.net\/link\/"#,
                                    #"^https:\/\/www\.bing\.com\/acli?c?k"#,
                                    #"^https:\/\/www\.bing\.com\/fd\/ls\/GLinkPingPost\.aspx.*acli?c?k"#]
        ),
        SearchProviderModel(
            name: BasicSearchProvider.bing.rawValue,
            regexp: #"^https:\/\/www\.bing\.com\/search"#,
            queryParam: "q",
            codeParam: "pc",
            codePrefixes: ["MOZ", "MZ"],
            followOnParams: ["oq"],
            extraAdServersRegexps: [
                #"^https:\/\/www\.bing\.com\/acli?c?k"#,
                #"^https:\/\/www\.bing\.com\/fd\/ls\/GLinkPingPost\.aspx.*acli?c?k"#
            ]
        ),
    ]
}

extension SearchProviderModel {
    func listAdUrls(urls: [String]) -> [String] {
        let predicates: [Predicate] = extraAdServersRegexps.map { regex in
            return { url in
                return url.range(of: regex, options: .regularExpression) != nil
            }
        }

        var adUrls = [String]()
        for url in urls {
            for predicate in predicates {
                guard predicate(url) else { continue }
                adUrls.append(url)
            }
        }
        
        return adUrls
    }
}

class AdsTelemetryHelper: TabContentScript {
    
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "Ads"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "adsMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard
            let provider = getProviderForMessage(message: message),
            let body = message.body as? [String : Any],
            let urls = body["urls"] as? [String] else { return }
        let adUrls = provider.listAdUrls(urls: urls)
        if !adUrls.isEmpty {
            AdsTelemetryHelper.trackAdsFoundOnPage(providerName: provider.name)
            tab?.adsProviderName = provider.name
            tab?.adsTelemetryUrlList = adUrls
            tab?.adsTelemetryRedirectUrlList.removeAll()
        }
    }
    
    private func getProviderForMessage(message: WKScriptMessage) -> SearchProviderModel? {
        guard let body = message.body as? [String : Any], let url = body["url"] as? String else { return nil }
        for provider in SearchProviderModel.searchProviderList {
            guard url.range(of: provider.regexp, options: .regularExpression) != nil else { continue }
            return provider
        }
        
        return nil
    }
    
    // Tracking
    
    public static func trackAdsFoundOnPage(providerName: String) {
        GleanMetrics.BrowserSearch.withAds["provider-\(providerName)"].add()
    }
    
    public static func trackAdsClickedOnPage(providerName: String) {
        GleanMetrics.BrowserSearch.adClicks["provider-\(providerName)"].add()
    }
}
