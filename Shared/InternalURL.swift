// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

// Internal URLs helps with error pages, session restore and about pages
public struct InternalURL {
    public static let uuid = UUID().uuidString
    public static let scheme = "internal"
    public static let baseUrl = "\(scheme)://local"
    public enum Path: String {
        case errorpage
        case sessionrestore
        func matches(_ string: String) -> Bool {
            return string.range(of: "/?\(self.rawValue)", options: .regularExpression, range: nil, locale: nil) != nil
        }
    }

    public enum Param: String {
        case uuidkey
        case url
        func matches(_ string: String) -> Bool { return string == self.rawValue }
    }

    public let url: URL

    private let sessionRestoreHistoryItemBaseUrl = "\(InternalURL.baseUrl)/\(InternalURL.Path.sessionrestore.rawValue)?url="

    public static func isValid(url: URL) -> Bool {
        let isWebServerUrl = url.absoluteString.hasPrefix("http://localhost:\(AppInfo.webserverPort)/")
        if isWebServerUrl, url.path.hasPrefix("/test-fixture/") {
            // internal test pages need to be treated as external pages
            return false
        }

        return isWebServerUrl || InternalURL.scheme == url.scheme
    }

    public init?(_ url: URL) {
        guard InternalURL.isValid(url: url) else { return nil }

        self.url = url
    }

    public var isAuthorized: Bool {
        return (url.getQuery()[InternalURL.Param.uuidkey.rawValue] ?? "") == InternalURL.uuid
    }

    public var stripAuthorization: String {
        guard var components = URLComponents(string: url.absoluteString), let items = components.queryItems else { return url.absoluteString }
        components.queryItems = items.filter { !Param.uuidkey.matches($0.name) }
        if let items = components.queryItems, items.isEmpty {
            components.queryItems = nil // This cleans up the url to not end with a '?'
        }
        return components.url?.absoluteString ?? ""
    }

    public static func authorize(url: URL) -> URL? {
        guard var components = URLComponents(string: url.absoluteString) else { return nil }
        if components.queryItems == nil {
            components.queryItems = []
        }

        if var item = components.queryItems?.find({ Param.uuidkey.matches($0.name) }) {
            item.value = InternalURL.uuid
        } else {
            components.queryItems?.append(URLQueryItem(name: Param.uuidkey.rawValue, value: InternalURL.uuid))
        }
        return components.url
    }

    public var isSessionRestore: Bool {
        return url.absoluteString.hasPrefix(sessionRestoreHistoryItemBaseUrl)
    }

    public var isErrorPage: Bool {
        // Error pages can be nested in session restore URLs, and session restore handler will forward them to the error page handler
        let path = url.absoluteString.hasPrefix(sessionRestoreHistoryItemBaseUrl) ? extractedUrlParam?.path : url.path
        return InternalURL.Path.errorpage.matches(path ?? "")
    }

    public var originalURLFromErrorPage: URL? {
        if !url.absoluteString.hasPrefix(sessionRestoreHistoryItemBaseUrl) {
            return isErrorPage ? extractedUrlParam : nil
        }
        if let urlParam = extractedUrlParam, let nested = InternalURL(urlParam), nested.isErrorPage {
            return nested.extractedUrlParam
        }
        return nil
    }

    public var extractedUrlParam: URL? {
        if let nestedUrl = url.getQuery()[InternalURL.Param.url.rawValue]?.unescape() {
            return URL(string: nestedUrl, invalidCharacters: false)
        }
        return nil
    }

    public var isAboutHomeURL: Bool {
        if let urlParam = extractedUrlParam, let internalUrlParam = InternalURL(urlParam) {
            return internalUrlParam.aboutComponent?.hasPrefix("home") ?? false
        }
        return aboutComponent?.hasPrefix("home") ?? false
    }

    public var isAboutURL: Bool {
        return aboutComponent != nil
    }

    /// Return the path after "about/" in the URI.
    public var aboutComponent: String? {
        let aboutPath = "/about/"
        guard let url = URL(string: stripAuthorization, invalidCharacters: false) else { return nil }

        if url.path.hasPrefix(aboutPath) {
            return String(url.path.dropFirst(aboutPath.count))
        }
        return nil
    }
}
