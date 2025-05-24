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

public class DefaultURLFormatter: URLFormatter {
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

        // Trim whitespace and encode any invalid characters
        let trimmedEntry = entry.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let escapedEntry = trimmedEntry.addingPercentEncoding(withAllowedCharacters: urlAllowed) else { return nil }

        guard let components = URLComponents(string: escapedEntry) else { return nil }

        // If the entry has a scheme, make sure it's safe then navigate to it
        if components.scheme != nil {
            return handleWithScheme(with: escapedEntry)
        }
        // If there's no scheme in the entry, try to format it as a URL with stricter checks
        return handleNoScheme(with: escapedEntry)
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
        guard let url = URL(string: entry),
              let components = URLComponents(string: entry) else { return nil }

        // Check if the URL includes a valid scheme
        if !url.schemeIsValid {
            return nil
        }

        // Require either a host or path
        if components.host == nil && components.path.isEmpty() {
            return nil
        }

        // If scheme is "http" or "https", check for a valid TLD
        if components.scheme == "http" || components.scheme == "https" {
            let lowercased = URL(string: entry.lowercased()) // to match TLDs correctly
            if !(url.isIPv4 || url.isIPv6) && lowercased?.publicSuffix == nil {
                return nil
            }
        }

        // Don't allow spaces in the host
        if components.host?.contains(" ") ?? false {
            return nil
        }

        if entry.range(of: "\\b:[0-9]{1,5}", options: .regularExpression) != nil {
            return nil
        }

        return checkBrowsingSafety(with: entry)
    }

    // Handle the entry if it has no scheme
    // If it passes the checks, prepend "http://" and call handleWithScheme()
    private func handleNoScheme(with entry: String) -> URL? {
        // If entry is a valid floating point number, don't fixup
        if Double(entry) != nil {
            return nil
        }

        // We're going to prepend "http://" as a default scheme
        let entryPlusScheme = "http://\(entry)"

        guard let components = URLComponents(string: entryPlusScheme) else { return nil }

        // Make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme
        if !(components.host?.contains(".") ?? false) { return nil }

        return handleWithScheme(with: entryPlusScheme)
    }

    private func checkBrowsingSafety(with entry: String) -> URL? {
        guard let url = URL(string: entry) else { return nil }

        // Only allow this URL if it's safe
        let browsingContext = BrowsingContext(type: .internalNavigation, url: url)
        if securityManager.canNavigateWith(browsingContext: browsingContext) == .allowed {
            return url
        } else {
            return nil
        }
    }
}
