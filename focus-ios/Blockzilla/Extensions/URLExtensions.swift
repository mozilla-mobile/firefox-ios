/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private struct ETLDEntry: CustomStringConvertible {
    let entry: String

    var isNormal: Bool { return isWild || !isException }
    var isWild: Bool = false
    var isException: Bool = false

    init(entry: String) {
        self.entry = entry
        self.isWild = entry.hasPrefix("*")
        self.isException = entry.hasPrefix("!")
    }

    fileprivate var description: String {
        return "{ Entry: \(entry), isWildcard: \(isWild), isException: \(isException) }"
    }
}

private typealias TLDEntryMap = [String: ETLDEntry]

private func loadEntriesFromDisk() -> TLDEntryMap? {
    guard let filepath = Bundle.main.path(forResource: "effective_tld_names", ofType: "dat"),
        let data = try? String(contentsOfFile: filepath) else {
        return nil
    }

    let lines = data.components(separatedBy: "\n")
    let trimmedLines = lines.filter { !$0.hasPrefix("//") && $0 != "\n" && $0 != "" }

    var entries = TLDEntryMap()
    for line in trimmedLines {
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
    return loadEntriesFromDisk()
}()

// MARK: - Local Resource URL Extensions
extension URL {

    public func allocatedFileSize() -> Int64 {
        // First try to get the total allocated size and in failing that, get the file allocated size
        return getResourceLongLongForKey(URLResourceKey.totalFileAllocatedSizeKey.rawValue)
            ?? getResourceLongLongForKey(URLResourceKey.fileAllocatedSizeKey.rawValue)
            ?? 0
    }

    public func getResourceValueForKey(_ key: String) -> Any? {
        let resourceKey = URLResourceKey(key)
        let keySet = Set<URLResourceKey>([resourceKey])

        var val: Any?
        do {
            let values = try resourceValues(forKeys: keySet)
            val = values.allValues[resourceKey]
        } catch _ {
            return nil
        }
        return val
    }

    public func getResourceLongLongForKey(_ key: String) -> Int64? {
        return (getResourceValueForKey(key) as? NSNumber)?.int64Value
    }

    public func getResourceBoolForKey(_ key: String) -> Bool? {
        return getResourceValueForKey(key) as? Bool
    }

    public var isRegularFile: Bool {
        return getResourceBoolForKey(URLResourceKey.isRegularFileKey.rawValue) ?? false
    }

    public func lastComponentIsPrefixedBy(_ prefix: String) -> Bool {
        return (pathComponents.last?.hasPrefix(prefix) ?? false)
    }
}

// The list of permanent URI schemes has been taken from http://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
private let permanentURISchemes = ["aaa", "aaas", "about", "acap", "acct", "cap", "cid", "coap", "coaps", "crid", "data", "dav", "dict", "dns", "example", "file", "ftp", "geo", "go", "gopher", "h323", "http", "https", "iax", "icap", "im", "imap", "info", "ipp", "ipps", "iris", "iris.beep", "iris.lwz", "iris.xpc", "iris.xpcs", "jabber", "ldap", "mailto", "mid", "msrp", "msrps", "mtqp", "mupdate", "news", "nfs", "ni", "nih", "nntp", "opaquelocktoken", "pkcs11", "pop", "pres", "reload", "rtsp", "rtsps", "rtspu", "service", "session", "shttp", "sieve", "sip", "sips", "sms", "snmp", "soap.beep", "soap.beeps", "stun", "stuns", "tag", "tel", "telnet", "tftp", "thismessage", "tip", "tn3270", "turn", "turns", "tv", "urn", "vemmi", "vnc", "ws", "wss", "xcon", "xcon-userid", "xmlrpc.beep", "xmlrpc.beeps", "xmpp", "z39.50r", "z39.50s"]

extension URL {

    public func withQueryParams(_ params: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        var items = (components.queryItems ?? [])
        for param in params {
            items.append(param)
        }
        components.queryItems = items
        return components.url!
    }

    public func withQueryParam(_ name: String, value: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        let item = URLQueryItem(name: name, value: value)
        components.queryItems = (components.queryItems ?? []) + [item]
        return components.url!
    }

    public func getQuery() -> [String: String] {
        var results = [String: String]()
        let keyValues = self.query?.components(separatedBy: "&")

        if keyValues?.count ?? 0 > 0 {
            for pair in keyValues! {
                let kv = pair.components(separatedBy: "=")
                if kv.count > 1 {
                    results[kv[0]] = kv[1]
                }
            }
        }

        return results
    }

    public static func getQuery(url: URL) -> [String: String] {
        var results = [String: String]()
        let keyValues =  url.query?.components(separatedBy: "&")

        if keyValues?.count ?? 0 > 0 {
            for pair in keyValues! {
                let kv = pair.components(separatedBy: "=")
                if kv.count > 1 {
                    results[kv[0]] = kv[1]
                }
            }
        }

        return results
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

    public var origin: String? {
        guard isWebPage(includeDataURIs: false), let hostPort = self.hostPort, let scheme = scheme else {
            return nil
        }
        return "\(scheme)://\(hostPort)"
    }

    /**
     * Returns the second level domain (SLD) of a url. It removes any subdomain/TLD
     *
     * E.g., https://m.foo.com/bar/baz?noo=abc#123  => foo
     **/
    public var hostSLD: String {
        guard let publicSuffix = self.publicSuffix, let baseDomain = self.baseDomain else {
            return self.normalizedHost ?? self.absoluteString
        }
        return baseDomain.replacingOccurrences(of: ".\(publicSuffix)", with: "")
    }

    public var normalizedHostAndPath: String? {
        return normalizedHost.flatMap { $0 + self.path }
    }

    public var absoluteDisplayString: String {
        var urlString = self.absoluteString
        // For http URLs, get rid of the trailing slash if the path is empty or '/'
        if (self.scheme == "http" || self.scheme == "https") && (self.path == "/") && urlString.hasSuffix("/") {
            urlString = String(urlString[..<urlString.index(urlString.endIndex, offsetBy: -1)])
        }
        // If it's basic http, strip out the string but leave anything else in
        if urlString.hasPrefix("http://") {
            return String(urlString[urlString.index(urlString.startIndex, offsetBy: 7)...])
        } else {
            return urlString
        }
    }

    /// String suitable for displaying outside of the app, for example in notifications, were Data Detectors will
    /// linkify the text and make it into a openable-in-Safari link.
    public var absoluteDisplayExternalString: String {
        return self.absoluteDisplayString.replacingOccurrences(of: ".", with: "\u{2024}")
    }

    /**
     Returns the base domain from a given hostname. The base domain name is defined as the public domain suffix
     with the base private domain attached to the front. For example, for the URL www.bbc.co.uk, the base domain
     would be bbc.co.uk. The base domain includes the public suffix (co.uk) + one level down (bbc).

     :returns: The base domain string for the given host name.
     */
    public var baseDomain: String? {
        guard host != nil else { return absoluteDisplayString }
        guard !isIPv4 && !isIPv6, let host = host else { return host }

        // If this is just a hostname and not a FQDN, use the entire hostname.
        if !host.contains(".") {
            return host
        }

        return publicSuffixFromHost(host, withAdditionalParts: 1) ?? host
    }

    /**
     * Returns just the domain, but with the same scheme, and a trailing '/'.
     *
     * E.g., https://m.foo.com/bar/baz?noo=abc#123  => https://foo.com/
     *
     * Any failure? Return this URL.
     */
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

    public var normalizedHost: String? {
        // Use components.host instead of self.host since the former correctly preserves
        // brackets for IPv6 hosts, whereas the latter strips them.
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), var host = components.host, host != "" else {
            return nil
        }

        if let range = host.range(of: "^(www|mobile|m)\\.", options: .regularExpression) {
            host.replaceSubrange(range, with: "")
        }

        return host
    }

    /**
     Returns the public portion of the host name determined by the public suffix list found here: https://publicsuffix.org/list/.
     For example for the url www.bbc.co.uk, based on the entries in the TLD list, the public suffix would return co.uk.

     :returns: The public suffix for within the given hostname.
     */
    public var publicSuffix: String? {
        return host.flatMap { publicSuffixFromHost($0, withAdditionalParts: 0) }
    }

    public func isWebPage(includeDataURIs: Bool = true) -> Bool {
        let schemes = includeDataURIs ? ["http", "https", "data"] : ["http", "https"]
        return scheme.map { schemes.contains($0) } ?? false
    }

    public func isWebPage() -> Bool {
        let schemes = ["http", "https"]
        if let scheme = scheme, schemes.contains(scheme) {
            return true
        }
        return false
    }

    // This helps find local urls that we do not want to show loading bars on.
    // These utility pages should be invisible to the user
    public var isLocalUtility: Bool {
        guard self.isLocal else {
            return false
        }
        let utilityURLs = ["/errors", "/about/sessionrestore", "/about/home", "/reader-mode"]
        return utilityURLs.contains { self.path.hasPrefix($0) }
    }

    public var isLocal: Bool {
        guard isWebPage(includeDataURIs: false) else {
            return false
        }
        // iOS forwards hostless URLs (e.g., http://:6571) to localhost.
        guard let host = host, !host.isEmpty else {
            return true
        }

        return host.lowercased() == "localhost" || host == "127.0.0.1"
    }

    public var isIPv4: Bool {
        let ipv4Pattern = #"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#

        return host?.range(of: ipv4Pattern, options: .regularExpression) != nil
    }

    public var isIPv6: Bool {
        return host?.contains(":") ?? false
    }

    /**
     Returns whether the URL's scheme is one of those listed on the official list of URI schemes.
     This only accepts permanent schemes: historical and provisional schemes are not accepted.
     */
    public var schemeIsValid: Bool {
        guard let scheme = scheme else { return false }
        return permanentURISchemes.contains(scheme.lowercased())
    }

    public func havingRemovedAuthorisationComponents() -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        urlComponents.user = nil
        urlComponents.password = nil
        if let url = urlComponents.url {
            return url
        }
        return self
    }

    /**
     * Returns a shorter displayable string for a domain
     *
     * E.g., https://m.foo.com/bar/baz?noo=abc#123  => foo
     *       https://accounts.foo.com/bar/baz?noo=abc#123  => accounts.foo
     **/
    public var shortDisplayString: String {
        guard let publicSuffix = self.publicSuffix, let baseDomain = self.normalizedHost else {
            return self.normalizedHost ?? self.absoluteString
        }
        return baseDomain.replacingOccurrences(of: ".\(publicSuffix)", with: "")
    }
}

// MARK: Private Helpers
private extension URL {
    func publicSuffixFromHost( _ host: String, withAdditionalParts additionalPartCount: Int) -> String? {
        if host.isEmpty {
            return nil
        }

        // Check edge case where the host is either a single or double '.'.
        if host.isEmpty || NSString(string: host).lastPathComponent == "." {
            return ""
        }

        /**
         *  The following algorithm breaks apart the domain and checks each sub domain against the effective TLD
         *  entries from the effective_tld_names.dat file. It works like this:
         *
         *  Example Domain: test.bbc.co.uk
         *  TLD Entry: bbc
         *
         *  1. Start off by checking the current domain (test.bbc.co.uk)
         *  2. Also store the domain after the next dot (bbc.co.uk)
         *  3. If we find an entry that matches the current domain (test.bbc.co.uk), perform the following checks:
         *    i. If the domain is a wildcard AND the previous entry is not nil, then the current domain matches
         *       since it satisfies the wildcard requirement.
         *    ii. If the domain is normal (no wildcard) and we don't have anything after the next dot, then
         *        currentDomain is a valid TLD
         *    iii. If the entry we matched is an exception case, then the base domain is the part after the next dot
         *
         *  On the next run through the loop, we set the new domain to check as the part after the next dot,
         *  update the next dot reference to be the string after the new next dot, and check the TLD entries again.
         *  If we reach the end of the host (nextDot = nil) and we haven't found anything, then we've hit the
         *  top domain level so we use it by default.
         */

        let tokens = host.components(separatedBy: ".")
        let tokenCount = tokens.count
        var suffix: String?
        var previousDomain: String? = nil
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
                let suffixlessHost = host.replacingOccurrences(of: suffix, with: "", options: literalFromEnd, range: nil)
                let suffixlessTokens = suffixlessHost.components(separatedBy: ".").filter { $0 != "" }
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
}
