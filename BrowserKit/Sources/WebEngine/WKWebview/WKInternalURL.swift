// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Internal URLs helps with error pages, session restore and about pages
protocol InternalURL {
    var isAuthorized: Bool { get }

    func authorize()
    func stripAuthorization()
}

final class WKInternalURL: InternalURL {
    static let uuid = UUID().uuidString
    static let scheme = "internal"
    static let baseUrl = "\(scheme)://local"

    enum Path: String {
        case errorpage
        func matches(_ string: String) -> Bool {
            return string.range(of: "/?\(self.rawValue)",
                                options: .regularExpression,
                                range: nil,
                                locale: nil) != nil
        }
    }

    enum Param: String {
        case uuidkey
        case url
        func matches(_ string: String) -> Bool { return string == self.rawValue }
    }

    var url: URL

    init?(_ url: URL) {
        guard WKInternalURL.isValid(url: url) else { return nil }

        self.url = url
    }

    static func isValid(url: URL) -> Bool {
        let isWebServerUrl = url.absoluteString.hasPrefix("http://localhost:\(WKEngineInfo.webserverPort)/")
        if isWebServerUrl, url.path.hasPrefix("/test-fixture/") {
            // internal test pages need to be treated as external pages
            return false
        }

        return isWebServerUrl || WKInternalURL.scheme == url.scheme
    }

    func authorize() {
        guard var components = URLComponents(string: url.absoluteString) else { return }
        if components.queryItems == nil {
            components.queryItems = []
        }

        if components.queryItems?.contains(where: { Param.uuidkey.matches($0.name) }) != true {
            components.queryItems?.append(URLQueryItem(name: Param.uuidkey.rawValue, value: WKInternalURL.uuid))
        }

        guard let url = components.url,
                WKInternalURL.isValid(url: url) else { return }
        self.url = url
    }

    func stripAuthorization() {
        guard var components = URLComponents(string: url.absoluteString),
                let items = components.queryItems else { return }
        components.queryItems = items.filter { !Param.uuidkey.matches($0.name) }
        if let items = components.queryItems, items.isEmpty {
            components.queryItems = nil // This cleans up the url to not end with a '?'
        }

        guard let url = components.url,
                WKInternalURL.isValid(url: url) else { return }
        self.url = url
    }

    var isAuthorized: Bool {
        let query = url.getQuery()
        return query[WKInternalURL.Param.uuidkey.rawValue] == WKInternalURL.uuid
    }

    var originalURLFromErrorPage: URL? {
        return isErrorPage ? extractedUrlParam : nil
    }

    private var extractedUrlParam: URL? {
        if let nestedUrl = url.getQuery()[WKInternalURL.Param.url.rawValue]?.removingPercentEncoding {
            return URL(string: nestedUrl, invalidCharacters: false)
        }
        return nil
    }

    private var isErrorPage: Bool {
        return WKInternalURL.Path.errorpage.matches(url.path)
    }
}
