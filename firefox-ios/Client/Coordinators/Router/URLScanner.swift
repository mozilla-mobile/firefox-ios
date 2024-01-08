// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A utility type for extracting information from URLs, specifically those with certain schemes
/// and formats used by the Mozilla Firefox browser.
///
/// - Note: This type is designed for use with URLs that conform to the expected format. Unexpected URLs may
///         result in nil values and/or incorrect information being returned.
struct URLScanner {
    /// The path components of the URL, excluding the scheme, host, and query parameters.
    var components: [String]

    /// The query parameters of the URL, as an array of `URLQueryItem` objects.
    var queries: [URLQueryItem]

    /// The scheme of the URL, such as "http" or "https".
    let scheme: String

    /// The host of the URL, such as "example.com".
    let host: String

    /// Initializes a new `URLScanner` object with the specified URL, if the URL is valid and uses a recognized scheme.
    ///
    /// - Parameter url: The URL to scan.
    ///
    /// - Returns: A new `URLScanner` object if the URL is valid and uses a recognized scheme, otherwise `nil`.
    init?(url: URL) {
        let url = URLScanner.sanitized(url: url)
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
              let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String]
        else {
            // Something very strange has happened; org.mozilla.Client should be the zeroeth URL type.
            return nil
        }

        guard let scheme = urlComponents.scheme, urlSchemes.contains(scheme) else { return nil }
        self.scheme = scheme
        self.host = urlComponents.host ?? ""
        self.components = URL(string: urlComponents.path, invalidCharacters: false)?.pathComponents ?? []
        self.queries = urlComponents.queryItems ?? []
    }

    /// Returns a Boolean value indicating whether the URL uses one of the expected
    /// Mozilla Firefox extension schemes.
    var isOurScheme: Bool {
        return [URL.mozPublicScheme, URL.mozInternalScheme].contains(self.scheme)
    }

    /// Returns the value of the specified query parameter in the URL's query string.
    ///
    /// - Parameter query: The name of the query parameter to retrieve.
    ///
    /// - Returns: The value of the specified query parameter, or `nil` if the parameter was not
    /// found in the URL's query string.
    func value(query: String) -> String? {
        return self.queries.first { $0.name == query }?.value
    }

    /// Returns the value of the 'url' query item, if it is present, and also adds any
    /// other trailing query parameters following the 'url' query onto the url value.
    ///
    /// For example, in this URL:
    ///     `firefox://open-url?url=https://test.com/page?arg1=a&arg2=b`
    /// this function returns:
    ///     `https://test.com/page?arg1=a&arg2=b`
    ///
    /// @Discussion
    /// The queryItems of the URLComponents will be listed in order, so we can scan up
    /// to the point at which we find the `url` parameter, and include that as well as
    /// any other arguments which are part of the URL.
    ///
    /// Important: this assumes that the `url` query item is the last query item within
    /// any deeplinks opened by the client. If any other query items are included after
    /// `url` then they will be incorrectly included in this query.
    ///
    /// Example:
    /// `firefox://example?url=https://mozilla.com/page?arg1=a&url2=https://mozilla.social`
    ///
    /// In the above URL, it may have intended `url2` to be part of the parent firefox://
    /// URL but using this function, it will add `url2` to the link of `url`.
    func fullURLQueryItem() -> String? {
        guard !queries.isEmpty else { return nil }

        guard let url = value(query: "url")?.asURL else { return nil }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        guard let urlQueryIndex = queries.firstIndex(where: { $0.name == "url" }) else { return nil }
        components.queryItems?.append(contentsOf: queries[((urlQueryIndex + 1)..<queries.count)])
        return components.string
    }

    /// Returns a Boolean value indicating whether the URL uses either the "http" or "https" scheme.
    var isHTTPScheme: Bool {
        return ["http", "https"].contains(scheme)
    }

    /// Force the URL's scheme to lowercase to ensure the code below can cope with URLs like
    /// the following from an external source. E.g Notes.app
    ///
    /// Https://www.apple.com
    ///
    static func sanitized(url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme, !scheme.isEmpty
        else { return url }

        components.scheme = scheme.lowercased()
        return components.url ?? url
    }
}
