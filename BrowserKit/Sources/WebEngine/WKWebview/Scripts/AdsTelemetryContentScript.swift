// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

public enum EngineBasicSearchProvider: String {
    case google
    case duckduckgo
    case yahoo
    case bing
}

public struct EngineSearchProviderModel {
    typealias Predicate = (String) -> Bool
    let name: String
    let regexp: String
    let queryParam: String
    let codeParam: String
    let codePrefixes: [String]
    let followOnParams: [String]
    let extraAdServersRegexps: [String]

    public static let searchProviderList = [
        EngineSearchProviderModel(
            name: EngineBasicSearchProvider.google.rawValue,
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
        EngineSearchProviderModel(
            name: EngineBasicSearchProvider.duckduckgo.rawValue,
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
        EngineSearchProviderModel(
            name: EngineBasicSearchProvider.yahoo.rawValue,
            regexp: #"^https:\/\/(?:.*)search\.yahoo\.com\/search"#,
            queryParam: "p",
            codeParam: "",
            codePrefixes: [],
            followOnParams: [],
            extraAdServersRegexps: [#"^(http|https):\/\/clickserve.dartsearch.net\/link\/"#,
                                    #"^https:\/\/www\.bing\.com\/acli?c?k"#,
                                    #"^https:\/\/www\.bing\.com\/fd\/ls\/GLinkPingPost\.aspx.*acli?c?k"#]
        ),
        EngineSearchProviderModel(
            name: EngineBasicSearchProvider.bing.rawValue,
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

extension EngineSearchProviderModel {
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

protocol AdsTelemetryScriptDelegate: AnyObject {
    func trackAdsFoundOnPage(providerName: String, urls: [String])
    func trackAdsClickedOnPage(providerName: String)
}

class AdsTelemetryContentScript: WKContentScript {
    private var logger: Logger
    private weak var delegate: AdsTelemetryScriptDelegate?

    init(logger: Logger = DefaultLogger.shared,
         delegate: AdsTelemetryScriptDelegate?) {
        self.logger = logger
        self.delegate = delegate
    }

    class func name() -> String {
        return "Ads"
    }

    func scriptMessageHandlerNames() -> [String] {
        return ["adsMessageHandler"]
    }

    func userContentController(didReceiveMessage message: Any) {
        guard
            let provider = getProviderForMessage(message: message),
            let body = message as? [String: Any],
            let urls = body["urls"] as? [String] else { return }
        let adUrls = provider.listAdUrls(urls: urls)
        if !adUrls.isEmpty {
            trackAdsFoundOnPage(providerName: provider.name, urls: adUrls)
        }
    }

    private func getProviderForMessage(message: Any) -> EngineSearchProviderModel? {
        guard let body = message as? [String: Any], let url = body["url"] as? String else { return nil }
        for provider in EngineSearchProviderModel.searchProviderList {
            guard url.range(of: provider.regexp, options: .regularExpression) != nil else { continue }
            return provider
        }

        return nil
    }

    // Tracking

    private func trackAdsFoundOnPage(providerName: String, urls: [String]) {
        delegate?.trackAdsFoundOnPage(providerName: providerName, urls: urls)
    }

    private func trackAdsClickedOnPage(providerName: String) {
        delegate?.trackAdsClickedOnPage(providerName: providerName)
    }
}
