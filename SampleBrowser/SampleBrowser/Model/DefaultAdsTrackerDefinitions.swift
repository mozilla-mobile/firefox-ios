// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebEngine

struct DefaultAdsTrackerDefinitions {
    static let searchProviders: [EngineSearchProviderModel] = [
           EngineSearchProviderModel(
               name: "google",
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
               name: "duckduckgo",
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
               name: "yahoo",
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
               name: "bing",
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
