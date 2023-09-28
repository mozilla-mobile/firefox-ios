// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A utility type for extracting information from URLs, specifically those with certain schemes and formats used by the Mozilla Firefox browser.
///
/// - Note: This type is designed for use with URLs that conform to the expected format. Unexpected URLs may result in nil values and/or incorrect information being returned.
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

    /// Returns a Boolean value indicating whether the URL uses one of the expected Mozilla Firefox extension schemes.
    var isOurScheme: Bool {
        return [URL.mozPublicScheme, URL.mozInternalScheme].contains(self.scheme)
    }

    /// Returns the value of the specified query parameter in the URL's query string.
    ///
    /// - Parameter query: The name of the query parameter to retrieve.
    ///
    /// - Returns: The value of the specified query parameter, or `nil` if the parameter was not found in the URL's query string.
    func value(query: String) -> String? {
        return self.queries.first { $0.name == query }?.value
    }

    /// Returns a Boolean value indicating whether the URL uses either the "http" or "https" scheme.
    var isHTTPScheme: Bool {
        return ["http", "https"].contains(scheme)
    }

    /// Force the URL's scheme to lowercase to ensure the code below can cope with URLs like the following from an external source. E.g Notes.app
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
