// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OhttpManager {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

enum OhttpError: Error {
    case KeyFetchFailed
    case RelayFailed
    case FaultyResponse
    case FaultyRequestURL
}

/// This class will be provided by Application-Services, we're stubbing it at the moment since it's not available yet
/// See https://mozilla-hub.atlassian.net/browse/FXIOS-13275 for more information
actor StubOhttpManager: OhttpManager {
    // The OhttpManager communicates with the relay and key server using
    // URLSession.shared.data unless an alternative networking method is
    // provided with this signature.
    typealias NetworkFunction = (_: URLRequest) async throws -> (Data, URLResponse)

    // Global cache to caching Gateway encryption keys. Stale entries are
    // ignored and on Gateway errors the key used should be purged and retrieved
    // again next at next network attempt.
    static var keyCache = [URL: ([UInt8], Date)]()

    private var configUrl: URL
    private var relayUrl: URL
    private var network: NetworkFunction

    init(configUrl: URL,
         relayUrl: URL,
         network: @escaping NetworkFunction = URLSession.shared.data) {
        self.configUrl = configUrl
        self.relayUrl = relayUrl
        self.network = network
    }

    private func fetchKey(url: URL) async throws -> [UInt8] {
        let request = URLRequest(url: url)
        if let (data, response) = try? await network(request),
           let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            return [UInt8](data)
        }

        throw OhttpError.KeyFetchFailed
    }

    private func keyForGateway(gatewayConfigUrl: URL, ttl: TimeInterval) async throws -> [UInt8] {
        if let (data, timestamp) = Self.keyCache[gatewayConfigUrl] {
            if Date() < timestamp + ttl {
                // Cache Hit!
                return data
            }

            Self.keyCache.removeValue(forKey: gatewayConfigUrl)
        }

        let data = try await fetchKey(url: gatewayConfigUrl)
        Self.keyCache[gatewayConfigUrl] = (data, Date())

        return data
    }

    private func invalidateKey() {
        Self.keyCache.removeValue(forKey: configUrl)
    }

    // Returning empty data for now since this is a stub
    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let config = try await keyForGateway(gatewayConfigUrl: configUrl,
                                             ttl: TimeInterval(3600))

        var request = URLRequest(url: relayUrl)
        request.httpMethod = "POST"
        request.setValue("message/ohttp-req", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()

        guard let responseURL = request.url else {
            throw OhttpError.FaultyRequestURL
        }

        guard let response = HTTPURLResponse(url: responseURL,
                                             statusCode: 200,
                                             httpVersion: "HTTP/1.1",
                                             headerFields: nil) else {
            throw OhttpError.FaultyResponse
        }

        return (Data(), response)
    }
}
