// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockAdsTelemetryDelegate: AdsTelemetryScriptDelegate {
    var trackAdsFoundOnPageCalled = 0
    var trackAdsClickedOnPageCalled = 0

    var savedTrackAdsOnPageProviderName: String?
    var savedTrackAdsOnPageURLs: [String]?

    func trackAdsFoundOnPage(providerName: String, urls: [String]) {
        trackAdsFoundOnPageCalled += 1
        savedTrackAdsOnPageURLs = urls
        savedTrackAdsOnPageProviderName = providerName
    }

    func trackAdsClickedOnPage(providerName: String) {
        trackAdsClickedOnPageCalled += 1
    }

    func searchProviderModels() -> [EngineSearchProviderModel] {
        return MockAdsTelemetrySearchProvider.mockSearchProviderModels()
    }
}

struct MockAdsTelemetrySearchProvider {
    static func mockSearchProviderModels() -> [WebEngine.EngineSearchProviderModel] {
        return [EngineSearchProviderModel(
                name: "mocksearch",
                regexp: #"^https:\/\/www\.mocksearch\.(?:.+)\/search"#,
                queryParam: "q",
                codeParam: "client",
                codePrefixes: ["firefox"],
                followOnParams: ["oq", "ved", "ei"],
                extraAdServersRegexps: [
                    #"^https?:\/\/www\.mocksearch(?:adservices)?\.com\/(?:pagead\/)?aclk"#,
                    #"^https?:\/\/www\.mocksearch(?:adservices)?\.com\/(?:pagead\/)?bclk"#,
                ]
            )]
    }
}
