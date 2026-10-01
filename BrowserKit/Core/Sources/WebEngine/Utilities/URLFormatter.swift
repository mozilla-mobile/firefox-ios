// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The URLFormatter is used to ensure we properly format given URL entered by a user.
/// The formatted URL is then input by the Client inside the SecurityManager to determine
/// if the BrowsingContext can be navigated to. If no formatted URL is found, then we make
/// a search with the entry as a search term.
public protocol URLFormatter {
    /// Try to get a URL from a user entry
    /// - Parameter entry: The text entered in the URL bar by the user
    /// - Returns: The formatted URL if we could format it. If this is nil, we should make
    /// a search term out of the entry instead.
    func getURL(entry: String) -> URL?
}

public final class DefaultURLFormatter: URLFormatter {
    private var securityManager: SecurityManager

    public init(securityManager: SecurityManager = DefaultSecurityManager()) {
        self.securityManager = securityManager
    }

    private var urlAllowed: CharacterSet {
        let allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%"
        return CharacterSet(charactersIn: allowed)
    }

    public func getURL(entry: String) -> URL? {
        // If it's an Internal URL no formatting should happen
        if let url = URL(string: entry), WKInternalURL.isValid(url: url) {
            return URL(string: entry)
        }

        // If the entry is `localhost` then navigate to it
        if let localHostURL = handleLocalHost(with: entry) {
            return localHostURL
        }

        // If the entry has a scheme, make sure it's safe then navigate to it
        if let schemeURL = handleWithScheme(with: entry) {
            return schemeURL
        }

        // If there's no scheme in the entry, try to format it as a URL
        return handleNoScheme(with: entry)
    }

    // Add exception of `localhost` to copy default desktop FF setting:
    // "browser.fixup.domainwhitelist.localhost" = true;
    private func handleLocalHost(with entry: String) -> URL? {
        if URL(string: "http://\(entry)")?.host?.localizedCaseInsensitiveContains("localhost") ?? false {
            return URL(string: "http://\(entry)")
        }
        return nil
    }

    // Handle the entry if it has a scheme, make sure it's safe before browsing to it
    private func handleWithScheme(with entry: String) -> URL? {
        // Check if the URL includes a scheme
        guard let url = handleURL(with: entry),
              url.scheme != nil,
              entry.range(of: "\\b:[0-9]{1,5}", options: .regularExpression) == nil else {
            return nil
        }

        // Check presence of top-level domain if scheme is "http://" or "https://"
        if entry.hasPrefix("http://") || entry.hasPrefix("https://") {
            if !entry.contains(".") {
                return nil
            }
        }

        // Only allow this URL if it's safe
        let browsingContext = BrowsingContext(type: .internalNavigation, url: url)
        if securityManager.canNavigateWith(browsingContext: browsingContext) == .allowed {
            return url
        } else {
            return nil
        }
    }

    private func handleURL(with entry: String) -> URL? {
        // Per Apple docs, for apps linked on or after iOS 17 and aligned OS versions, URL parsing has updated
        // from the obsolete RFC 1738/1808 parsing to the same RFC 3986 parsing as URLComponents.
        // iOS 17+, URL automatically percent- and IDNA-encodes invalid characters to help create a valid URL.

        if #available(iOS 17, *) {
            return URL(string: entry)
        } else {
            // We only want to do percent encoding on our other schemes
            let hasHTTPScheme = entry.hasPrefix("http://") || entry.hasPrefix("https://")
            guard !hasHTTPScheme else { return URL(string: entry) }

            // FXIOS-14375 - Manually add percent encoding since it's not handled by URL(string:) in < iOS 17
            guard let escapedURL = entry.addingPercentEncoding(withAllowedCharacters: urlAllowed) else {
                return nil
            }
            guard let finalURL = URL(string: escapedURL), schemeIsValid(for: finalURL) else { return nil }
            return finalURL
        }
    }

    /**
     Returns whether the URL's scheme is one of those listed on the official list of URI schemes.
     This only accepts permanent schemes: historical and provisional schemes are not accepted.
     */
    func schemeIsValid(for url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        return SchemesDefinition.permanentURISchemes.contains(scheme.lowercased())
               && url.absoluteString.lowercased() != scheme + ":"
    }

    // Handle the entry if it has no scheme
    private func handleNoScheme(with entry: String) -> URL? {
        // First trim white spaces
        let trimmedEntry = entry.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        // Make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme
        if !trimmedEntry.contains(".") || trimmedEntry.contains(" ") { return nil }

        // If entry is a valid floating point number, don't fixup
        if Double(trimmedEntry) != nil {
            return nil
        }

        // If entry doesn't have a valid ending in Public Suffix List
        // and it's not all digits and dot, stop fix up.
        if !trimmedEntry.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.")).isEmpty,
           let maybeUrl = URL(string: "http://\(trimmedEntry.lowercased())"),
           maybeUrl.publicSuffix == nil {
            return nil
        }

        // Make sure entry only has allowed characters in it
        guard let escapedURL = trimmedEntry.addingPercentEncoding(withAllowedCharacters: urlAllowed) else {
            return nil
        }

        // We're going to prepend "http://" only if it's not already present
        let finalURL = escapedURL.hasPrefix("http://") || escapedURL.hasPrefix("https://") ? escapedURL : "http://\(escapedURL)"

        // If there is a host, return this formatted as a URL
        if let url = URL(string: finalURL), url.host != nil {
            return url
        }

        return nil
    }
}
