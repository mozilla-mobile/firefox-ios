// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation

enum FxAPairingURLParser {
    enum ParseResult: Equatable {
        case notPairing
        case invalidPairing
        case pairing(URL)
    }

    static func parse(
        _ url: URL,
        contentServer: URL? = nil
    ) -> ParseResult {
        // Only the content server this build is configured against can pair, so a local FxA
        // stack routes during testing while a stray host never does. Same rule the WebChannel
        // bridge applies before it will talk to a page.
        let server = contentServer ?? RustFirefoxAccounts.contentServerURL()
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let server,
              let host = components.host?.lowercased(),
              host == server.host?.lowercased()
        else { return .notPairing }

        let path = normalized(path: components.path)
        guard path == "/pair" else { return .notPairing }

        let parameters = pairingParameters(in: components)
        let pairingVersion = parameters.first(where: { $0.name == "v" })?.value
        guard pairingVersion == "2" else { return .notPairing }

        // Our host on the wrong scheme or port is a downgrade attempt, not someone else's link.
        // Cleartext stays confined to a loopback stack, so a custom content server pointed at a
        // remote http:// origin can never make a plaintext pairing link valid.
        let scheme = components.scheme?.lowercased()
        guard scheme == server.scheme?.lowercased(),
              scheme == "https" || (scheme == "http" && isLoopback(host: host)),
              port(of: components.port, scheme: scheme) == port(of: server.port, scheme: server.scheme),
              components.user == nil,
              components.password == nil
        else { return .invalidPairing }

        guard hasChannelCredentials(in: parameters) else { return .invalidPairing }
        guard let normalized = normalized(components: components, scheme: scheme, host: host) else {
            return .invalidPairing
        }
        return .pairing(normalized)
    }

    /// The WebChannel bridge compares this URL against `WKSecurityOrigin`, which reports a
    /// lowercased host and port 0 for a scheme default. Emit the URL in that same shape, so the
    /// two origin gates cannot disagree and leave the page talking to a bridge that ignores it.
    private static func normalized(components: URLComponents, scheme: String?, host: String) -> URL? {
        var normalized = components
        if normalized.scheme != scheme {
            normalized.scheme = scheme
        }
        if normalized.host != host {
            normalized.host = host
        }
        if let port = normalized.port, port == defaultPort(forScheme: scheme) {
            normalized.port = nil
        }
        return normalized.url
    }

    /// No IPv6 literal here on purpose: this is compared against `URLComponents.host`, which keeps
    /// the brackets, while the configured server host comes from `URL.host`, which strips them, so
    /// an IPv6 loopback server could never match either side. A local stack uses `localhost`.
    private static let loopbackHosts: Set<String> = ["localhost", "127.0.0.1"]

    private static func isLoopback(host: String) -> Bool {
        return loopbackHosts.contains(host)
    }

    /// An omitted port means the scheme's default, so compare the resolved values rather than the
    /// literal optionals: `https://host` and `https://host:443` are the same origin.
    private static func port(of port: Int?, scheme: String?) -> Int? {
        return port ?? defaultPort(forScheme: scheme)
    }

    private static func defaultPort(forScheme scheme: String?) -> Int? {
        switch scheme?.lowercased() {
        case "https": return 443
        case "http": return 80
        default: return nil
        }
    }

    private static func normalized(path: String) -> String {
        guard path.count > 1, path.hasSuffix("/") else { return path }
        return String(path.dropLast())
    }

    private static func pairingParameters(in components: URLComponents) -> [URLQueryItem] {
        let queryItems = components.queryItems ?? []
        let fragmentItems: [URLQueryItem]
        if let fragment = components.fragment {
            var fragmentComponents = URLComponents()
            fragmentComponents.query = fragment
            fragmentItems = fragmentComponents.queryItems ?? []
        } else {
            fragmentItems = []
        }

        return queryItems + fragmentItems
    }

    private static func hasChannelCredentials(in parameters: [URLQueryItem]) -> Bool {
        let channelID = parameters.first(where: { $0.name == "channel_id" })?.value
        let channelKey = parameters.first(where: { $0.name == "channel_key" })?.value
        return channelID?.isEmpty == false && channelKey?.isEmpty == false
    }
}
