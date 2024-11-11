// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URL {
    /// Temporary init that will be removed with the update to XCode 15 where this URL API is available
    public init?(string: String, invalidCharacters: Bool) {
        // FXIOS-8107: Removed 'encodingInvalidCharacters' init for
        // compatibility reasons that is available for iOS 17+ only
        self.init(string: string)
    }

    /// Returns a shorter displayable string for a domain
    /// E.g., https://m.foo.com/bar/baz?noo=abc#123  => foo
    /// https://accounts.foo.com/bar/baz?noo=abc#123  => accounts.foo
    public var shortDisplayString: String {
        guard let publicSuffix = self.publicSuffix, let baseDomain = self.normalizedHost else {
            return self.normalizedHost ?? self.absoluteString
        }
        return baseDomain.replacingOccurrences(of: ".\(publicSuffix)", with: "")
    }

    /// Returns just the domain, but with the same scheme, and a trailing '/'.
    /// E.g., https://m.foo.com/bar/baz?noo=abc#123  => https://foo.com/
    /// Any failure? Return this URL.
    public var domainURL: URL {
        if let normalized = self.normalizedHost {
            // Use NSURLComponents instead of NSURL since the former correctly preserves
            // brackets for IPv6 hosts, whereas the latter escapes them.
            var components = URLComponents()
            components.scheme = self.scheme
            components.port = self.port
            components.host = normalized
            components.path = "/"
            return components.url ?? self
        }
        return self
    }

    /// Creates a short domain version of a link's url
    /// e.g. url: http://www.foosite.com  =>  "foosite"
    public var shortDomain: String? {
        return host.flatMap { shortDomain($0, etld: publicSuffix ?? "") }
    }

    /// Returns the base domain from a given hostname. The base domain name is defined as the public domain suffix
    /// with the base private domain attached to the front. For example, for the URL www.bbc.co.uk, the base domain
    /// would be bbc.co.uk. The base domain includes the public suffix (co.uk) + one level down (bbc).
    /// :returns: The base domain string for the given host name.
    public var baseDomain: String? {
        guard !isIPv6, let host = host else { return nil }

        // If this is just a hostname and not a FQDN, use the entire hostname.
        if !host.contains(".") {
            return host
        }

        return publicSuffixFromHost(host, withAdditionalParts: 1)
    }

    public var normalizedHost: String? {
        // Use components.host instead of self.host since the former correctly preserves
        // brackets for IPv6 hosts, whereas the latter strips them.
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              var host = components.host,
              !host.isEmpty
        else { return nil }

        if let range = host.range(of: "^(www|mobile|m)\\.", options: .regularExpression) {
            host.replaceSubrange(range, with: "")
        }
        // If the host equals the public suffix, it means that the host is already normalized.
        // Therefore, we return the original host without any modifications.
        guard host != publicSuffix else { return components.host }

        return host
    }

    var normalizedHostAndPath: String? {
        return normalizedHost.flatMap { $0 + self.path }
    }

    /// Extracts the subdomain and host from a given URL string and appends a dot to the subdomain.
    ///
    /// This function takes a URL string as input and returns a tuple containing the subdomain and the normalized host.
    /// If the URL string does not contain a subdomain, the function returns `nil` for the subdomain. 
    /// If a subdomain is present, it is returned with a trailing dot.
    ///
    /// - Parameter urlString: The URL string to extract the subdomain and host from.
    ///
    /// - Returns: A tuple containing the subdomain (with a trailing dot) and the normalized host.
    ///  The subdomain is optional and may be `nil`.
    ///
    /// # Example
    /// ```
    /// let (subdomain, host) = getSubdomainAndHost(from: "https://docs.github.com")
    /// print(subdomain) // Prints "docs."
    /// print(host) // Prints "docs.github.com"
    /// ```
    public static func getSubdomainAndHost(from urlString: String) -> (subdomain: String?, normalizedHost: String) {
        guard let url = URL(string: urlString) else { return (nil, urlString) }
        let normalizedHost = url.normalizedHost ?? urlString

        guard let publicSuffix = url.publicSuffix else { return (nil, normalizedHost) }

        let publicSuffixComponents = publicSuffix.split(separator: ".")

        let normalizedHostWithoutSuffix = normalizedHost
            .split(separator: ".")
            .dropLast(publicSuffixComponents.count)
            .joined(separator: ".")

        let components = normalizedHostWithoutSuffix.split(separator: ".")

        guard components.count >= 2 else { return (nil, normalizedHost) }
        let subdomain = components.dropLast()
                                  .joined(separator: ".")
                                  .appending(".")
        return (subdomain, normalizedHost)
    }

    /// Returns the public portion of the host name determined by the public suffix list found here: https://publicsuffix.org/list/.
    /// For example for the url www.bbc.co.uk, based on the entries in the TLD list, the public suffix would return co.uk.
    /// :returns: The public suffix for within the given hostname.
    public var publicSuffix: String? {
        return host.flatMap { publicSuffixFromHost($0, withAdditionalParts: 0) }
    }

    var isIPv6: Bool {
        return host?.contains(":") ?? false
    }

    /// Creates a short domain version of a link's url
    /// e.g. url: http://www.foosite.com  =>  "foosite"
    /// - Parameters:
    ///   - host: hostname
    ///   - etld: top level domain to remove from host
    /// - Returns: The short version of the domain
    func shortDomain(_ host: String, etld: String) -> String? {
        // Check edge case where the host is either a single or double '.'.
        if host.isEmpty || NSString(string: host).lastPathComponent == "." {
            return ""
        }

        // Clean up the url by removing www.
        var hostname = host.replacingOccurrences(of: "www.", with: "")
        hostname = hostname.replacingOccurrences(of: ".\(etld)", with: "")

        return hostname
    }

    func publicSuffixFromHost(_ host: String, withAdditionalParts additionalPartCount: Int) -> String? {
        if host.isEmpty {
            return nil
        }

        // Check edge case where the host is either a single or double '.'.
        if host.isEmpty || NSString(string: host).lastPathComponent == "." {
            return ""
        }

        // The following algorithm breaks apart the domain and checks each sub domain against the effective TLD
        // entries from the effective_tld_names.dat file. It works like this:
        //
        // Example Domain: test.bbc.co.uk
        // TLD Entry: bbc
        //
        // 1. Start off by checking the current domain (test.bbc.co.uk)
        // 2. Also store the domain after the next dot (bbc.co.uk)
        // 3. If we find an entry that matches the current domain (test.bbc.co.uk), perform the following checks:
        //   i. If the domain is a wildcard AND the previous entry is not nil, then the current domain matches
        //      since it satisfies the wildcard requirement.
        //   ii. If the domain is normal (no wildcard) and we don't have anything after the next dot, then
        //       currentDomain is a valid TLD
        //   iii. If the entry we matched is an exception case, then the base domain is the part after the next dot
        //
        // On the next run through the loop, we set the new domain to check as the part after the next dot,
        // update the next dot reference to be the string after the new next dot, and check the TLD entries again.
        // If we reach the end of the host (nextDot = nil) and we haven't found anything, then we've hit the
        // top domain level so we use it by default.

        let tokens = host.components(separatedBy: ".")
        let tokenCount = tokens.count
        var suffix: String?
        var previousDomain: String?
        var currentDomain: String = host

        for offset in 0..<tokenCount {
            // Store the offset for use outside of this scope so we can add additional parts if needed
            let nextDot: String? = offset + 1 < tokenCount ? tokens[offset + 1..<tokenCount].joined(separator: ".") : nil

            if let entry = etldEntries?[currentDomain] {
                if entry.isWild && (previousDomain != nil) {
                    suffix = previousDomain
                    break
                } else if entry.isNormal || (nextDot == nil) {
                    suffix = currentDomain
                    break
                } else if entry.isException {
                    suffix = nextDot
                    break
                }
            }

            previousDomain = currentDomain
            if let nextDot = nextDot {
                currentDomain = nextDot
            } else {
                break
            }
        }

        var baseDomain: String?
        if additionalPartCount > 0 {
            if let suffix = suffix {
                // Take out the public suffixed and add in the additional parts we want.
                let literalFromEnd: NSString.CompareOptions = [.literal,        // Match the string exactly.
                                     .backwards,      // Search from the end.
                                     .anchored]         // Stick to the end.
                let suffixlessHost = host.replacingOccurrences(
                    of: suffix,
                    with: "",
                    options: literalFromEnd,
                    range: nil
                )
                let suffixlessTokens = suffixlessHost.components(separatedBy: ".").filter { !$0.isEmpty }
                let maxAdditionalCount = max(0, suffixlessTokens.count - additionalPartCount)
                let additionalParts = suffixlessTokens[maxAdditionalCount..<suffixlessTokens.count]
                let partsString = additionalParts.joined(separator: ".")
                baseDomain = [partsString, suffix].joined(separator: ".")
            } else {
                return nil
            }
        } else {
            baseDomain = suffix
        }

        return baseDomain
    }

    public var absoluteDisplayString: String {
        var urlString = absoluteString
        // For http URLs, get rid of the trailing slash if the path is empty or '/'
        if (scheme == "http" || scheme == "https") && (path == "/") && urlString.hasSuffix("/") {
            urlString = String(urlString[..<urlString.index(urlString.endIndex, offsetBy: -1)])
        }
        // If it's basic http, strip out the string but leave anything else in
        if urlString.hasPrefix("http://") {
            return String(urlString[urlString.index(urlString.startIndex, offsetBy: 7)...])
        } else {
            return urlString
        }
    }

    public func removeBlobFromUrl() -> URL {
        let urlString = absoluteString
        guard scheme == "blob" else {
            return self
        }

        let stringURL = String(urlString[urlString.index(urlString.startIndex, offsetBy: 5)...])
        return URL(string: stringURL) ?? self
    }

    public func getQuery() -> [String: String] {
        var results = [String: String]()

        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.percentEncodedQueryItems
        else {
            return results
        }

        for item in queryItems {
            if let value = item.value {
                results[item.name] = value
            }
        }

        return results
    }

    public var origin: String? {
        guard isWebPage(includeDataURIs: false),
              let hostPort = self.hostPort,
              let scheme = scheme
        else { return nil }

        return "\(scheme)://\(hostPort)"
    }

    public var hostPort: String? {
        if let host = self.host {
            if let port = (self as NSURL).port?.int32Value {
                return "\(host):\(port)"
            }
            return host
        }
        return nil
    }

    public func isWebPage(includeDataURIs: Bool = true) -> Bool {
        let schemes = includeDataURIs ? ["http", "https", "data"] : ["http", "https"]
        return scheme.map { schemes.contains($0) } ?? false
    }

    /// Returns the standard location of the website's favicon. (This is the base directoy path with
    /// favicon.ico appended).
    public func faviconUrl() -> URL? {
        if let host = host, let rootDirectoryURL = URL(string: (scheme ?? "https") + "://" + host) {
            return rootDirectoryURL.appendingPathComponent("favicon.ico")
        }
        return nil
    }
}

private struct ETLDEntry: CustomStringConvertible {
    let entry: String

    var isNormal: Bool { return isWild || !isException }
    var isWild = false
    var isException = false

    init(entry: String) {
        self.entry = entry
        self.isWild = entry.hasPrefix("*")
        self.isException = entry.hasPrefix("!")
    }

    var description: String {
        return "{ Entry: \(entry), isWildcard: \(isWild), isException: \(isException) }"
    }
}

private typealias TLDEntryMap = [String: ETLDEntry]

private func loadEntries() -> TLDEntryMap? {
    var entries = TLDEntryMap()
    for line in ETLD_NAMES_LIST where !line.isEmpty && !line.hasPrefix("//") {
        let entry = ETLDEntry(entry: line)
        let key: String
        if entry.isWild {
            // Trim off the '*.' part of the line
            key = String(line[line.index(line.startIndex, offsetBy: 2)...])
        } else if entry.isException {
            // Trim off the '!' part of the line
            key = String(line[line.index(line.startIndex, offsetBy: 1)...])
        } else {
            key = line
        }
        entries[key] = entry
    }
    return entries
}

private var etldEntries: TLDEntryMap? = {
    return loadEntries()
}()
