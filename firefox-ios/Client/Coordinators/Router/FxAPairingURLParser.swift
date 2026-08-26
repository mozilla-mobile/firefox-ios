// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum FxAPairingURLParser {
    enum ParseResult: Equatable {
        case notPairing
        case invalidPairing
        case pairing(URL)
    }

    private static let allowedHosts = [
        "accounts.firefox.com",
        "accounts.stage.mozaws.net"
    ]

    static func parse(_ url: URL) -> ParseResult {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host?.lowercased(),
              allowedHosts.contains(host)
        else { return .notPairing }

        let path = normalized(path: components.path)
        guard path == "/pair" else { return .notPairing }

        let parameters = pairingParameters(in: components)
        let pairingVersion = parameters.first(where: { $0.name == "v" })?.value
        guard pairingVersion == "2" else { return .notPairing }

        guard components.scheme?.lowercased() == "https",
              components.user == nil,
              components.password == nil
        else { return .invalidPairing }

        guard hasChannelCredentials(in: parameters) else { return .invalidPairing }
        return .pairing(url)
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
