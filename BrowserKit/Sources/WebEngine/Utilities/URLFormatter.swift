// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The URLFormatter is used to ensure we properly format given URL entered by a user.
/// The formatted URL is then input by the Client inside the SecurityManager to determine if the BrowsingContext can be navigated to.
/// If no formatted URL is found, then we make a search with the entry as a search term.
public protocol URLFormatter {
    func getURL(entry: String) -> URL?
}

public class DefaultURLFormatter: URLFormatter {
    private var securityManager: SecurityManager

    init(securityManager: SecurityManager = DefaultSecurityManager()) {
        self.securityManager = securityManager
    }

    private var urlAllowed: CharacterSet {
        return CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%")
    }

    public func getURL(entry: String) -> URL? {
        // if it's an Internal URL no formatting should happen
        if let url = URL(string: entry, invalidCharacters: false), WKInternalURL.isValid(url: url) {
            return URL(string: entry, invalidCharacters: false)
        }

        let trimmed = entry.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let escapedURL = trimmed.addingPercentEncoding(withAllowedCharacters: urlAllowed) else {
            return nil
        }

        // Add exception of `localhost` to copy default desktop FF setting:
        // "browser.fixup.domainwhitelist.localhost" = true;
        if URL(string: "http://\(trimmed)")?.host?.localizedCaseInsensitiveContains("localhost") ?? false {
            return URL(string: "http://\(trimmed)")
        }

        // Check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        // Also check with a regular expression if there is a port in the url
        // this will be handle later in this function adding http prefix
        if let url = URL(string: trimmed, invalidCharacters: false),
           url.scheme != nil,
           trimmed.range(of: "\\b:[0-9]{1,5}", options: .regularExpression) == nil {

            // check for top-level domain if scheme is "http://" or "https://"
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                if trimmed.range(of: ".") == nil {
                    return nil
                }
            }
            
            let browsingContext = BrowsingContext(type: .internalNavigation,
                                                  url: trimmed)
            if securityManager.canNavigateWith(browsingContext: browsingContext) == .allowed {
                return URL(string: trimmed, invalidCharacters: false)
            }
        }

        // If there's no scheme, we're going to prepend "http://". First,
        // make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme
        if !trimmed.contains(".") || trimmed.contains(" ") { return nil }

        // If entry is a valid floating point number, don't fixup
        if Double(trimmed) != nil {
            return nil
        }

        // If entry doesn't have a valid ending in Public Suffix List
        // and it's not all digits and dot, stop fix up.
        if !trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.")).isEmpty,
           let maybeUrl = URL(string: "http://\(trimmed.lowercased())"),
           maybeUrl.publicSuffix == nil {
            return nil
        }

        // If the input url has a prefix http or https, don't append again
        let finalURL = escapedURL.hasPrefix("http://") || escapedURL.hasPrefix("https://") ? escapedURL : "http://\(escapedURL)"

        // If there is a ".", prepend "http://" and try again. Since this
        // is strictly an "http://" URL, we also require a host.
        if let url = URL(string: finalURL, invalidCharacters: false), url.host != nil {
            return url
        }

        return nil
    }
}
