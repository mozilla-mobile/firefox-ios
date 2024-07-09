// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

public struct EngineSearchProviderModel {
    typealias Predicate = (String) -> Bool
    let name: String
    let regexp: String
    let queryParam: String
    let codeParam: String
    let codePrefixes: [String]
    let followOnParams: [String]
    let extraAdServersRegexps: [String]

    public init(name: String,
                regexp: String,
                queryParam: String,
                codeParam: String,
                codePrefixes: [String],
                followOnParams: [String],
                extraAdServersRegexps: [String]) {
        self.name = name
        self.regexp = regexp
        self.queryParam = queryParam
        self.codeParam = codeParam
        self.codePrefixes = codePrefixes
        self.followOnParams = followOnParams
        self.extraAdServersRegexps = extraAdServersRegexps
    }

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

/// Delegate protocol for AdsTelemetryContentScript. Provides callbacks to delegates for ad tracking detection
/// and allows the delegate to provide the search engine definitions and regexes. (See: `EngineSearchProviderModel`)
protocol AdsTelemetryScriptDelegate: AnyObject {
    func trackAdsFoundOnPage(providerName: String, urls: [String])
    func trackAdsClickedOnPage(providerName: String)
    func searchProviderModels() -> [EngineSearchProviderModel]
}

/// Script utility to handle tracking of ads on pages, based on provided search engine regexes. (See `searchProviderModels`)
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

    // MARK: - Utility

    private func getProviderForMessage(message: Any) -> EngineSearchProviderModel? {
        guard let searchProviderModels = delegate?.searchProviderModels() else { return nil }
        guard let body = message as? [String: Any], let url = body["url"] as? String else { return nil }
        for provider in searchProviderModels {
            guard url.range(of: provider.regexp, options: .regularExpression) != nil else { continue }
            return provider
        }

        return nil
    }

    // MARK: - Tracking

    private func trackAdsFoundOnPage(providerName: String, urls: [String]) {
        delegate?.trackAdsFoundOnPage(providerName: providerName, urls: urls)
    }

    private func trackAdsClickedOnPage(providerName: String) {
        // TODO: [FXIOS-8629] This will require some client-side integration and hooks. Will revisit soon.
        delegate?.trackAdsClickedOnPage(providerName: providerName)
    }
}
