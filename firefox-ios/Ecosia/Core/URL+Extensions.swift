// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URL {

    public enum Key: String {
        case
        query = "q",
        typeTag = "tt",
        userId = "_sp"
    }

    public static func ecosiaSearchWithQuery(_ query: String, urlProvider: URLProvider = Environment.current.urlProvider) -> URL {
        var components = URLComponents(url: urlProvider.root, resolvingAgainstBaseURL: false)!
        components.path = "/search"
        components.queryItems = [item(key: .query, value: query), item(key: .typeTag, value: "iosapp")]
        return components.url!
    }

    /// Check whether the URL being browsed will present the SERP out of a search or a search suggestion
    public func isEcosiaSearchQuery(_ urlProvider: URLProvider = Environment.current.urlProvider) -> Bool {
        guard isEcosia(urlProvider),
              let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return false
        }
        return components.path == "/search"
    }

    /// Check whether the URL should be Ecosified. At the moment this is true for every Ecosia URL.
    public func shouldEcosify(_ urlProvider: URLProvider = Environment.current.urlProvider) -> Bool {
        return isEcosia(urlProvider)
    }

    public func ecosified(isIncognitoEnabled: Bool, urlProvider: URLProvider = Environment.current.urlProvider) -> URL {
        guard isEcosia(urlProvider),
              var components = components
        else { return self }
        components.queryItems?.removeAll(where: { $0.name == Key.userId.rawValue })
        var items = components.queryItems ?? .init()
        /* 
         The `sendAnonymousUsageData` is set by the native UX component in settings
         that determines whether the app would send the events to Snowplow.
         To align the business logic, this parameter will also function as a condition
         that decides whether we would send our AnalyticsID as query paramter for
         searches. In this scenario thuogh, the naming is a bit misleanding, thus
         checking for the negative evaluation of it.
         */
        let shouldAnonymizeUserId = isIncognitoEnabled ||
                                    !User.shared.hasAnalyticsCookieConsent ||
                                    !User.shared.sendAnonymousUsageData
        let userId = shouldAnonymizeUserId ? UUID(uuid: UUID_NULL).uuidString : User.shared.analyticsId.uuidString
        items.append(Self.item(key: .userId, value: userId))
        components.queryItems = items
        return components.url!
    }

    public var policy: Scheme.Policy {
        (scheme
            .flatMap(Scheme.init(rawValue:)) ?? .other)
            .policy
    }

    private subscript(_ key: Key) -> String? {
        components?.queryItems?.first { $0.name == key.rawValue }?.value
    }

    private func isEcosia(_ urlProvider: URLProvider = Environment.current.urlProvider) -> Bool {
        guard let domain = urlProvider.domain else { return false }
        let isBrowser = scheme.flatMap(Scheme.init(rawValue:))?.isBrowser == true
        let hasURLProviderDomainSuffix = host?.hasSuffix(domain) == true
        return isBrowser && hasURLProviderDomainSuffix
    }

    private var components: URLComponents? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)
    }

    private static func item(key: Key, value: String) -> URLQueryItem {
        .init(name: key.rawValue, value: value)
    }
}
