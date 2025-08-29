/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class OhttpManager {
    // The OhttpManager communicates with the relay and key server using
    // URLSession.shared.data unless an alternative networking method is
    // provided with this signature.
    public typealias NetworkFunction = (_: URLRequest) async throws -> (Data, URLResponse)

    // Global cache to caching Gateway encryption keys. Stale entries are
    // ignored and on Gateway errors the key used should be purged and retrieved
    // again next at next network attempt.
    static var keyCache = [URL: ([UInt8], Date)]()

    private var configUrl: URL
    private var relayUrl: URL
    private var network: NetworkFunction

    public init(configUrl: URL,
                relayUrl: URL,
                network: @escaping NetworkFunction = URLSession.shared.data)
    {
        self.configUrl = configUrl
        self.relayUrl = relayUrl
        self.network = network
    }

    private func fetchKey(url: URL) async throws -> [UInt8] {
        let request = URLRequest(url: url)
        if let (data, response) = try? await network(request),
           let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200
        {
            return [UInt8](data)
        }

        throw OhttpError.KeyFetchFailed(message: "Failed to fetch encryption key")
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

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Get the encryption keys for Gateway
        let config = try await keyForGateway(gatewayConfigUrl: configUrl,
                                             ttl: TimeInterval(3600))

        // Create an encryption session for a request-response round-trip
        let session = try OhttpSession(config: config)

        // Encapsulate the URLRequest for the Target
        let encoded = try session.encapsulate(method: request.httpMethod ?? "GET",
                                              scheme: request.url!.scheme!,
                                              server: request.url!.host!,
                                              endpoint: request.url!.path,
                                              headers: request.allHTTPHeaderFields ?? [:],
                                              payload: [UInt8](request.httpBody ?? Data()))

        // Request from Client to Relay
        var request = URLRequest(url: relayUrl)
        request.httpMethod = "POST"
        request.setValue("message/ohttp-req", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(encoded)

        let (data, response) = try await network(request)

        // Decapsulation failures have these codes, so invalidate any cached
        // keys in case the gateway has changed them.
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 400 ||
           httpResponse.statusCode == 401
        {
            invalidateKey()
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw OhttpError.RelayFailed(message: "Network errors communicating with Relay / Gateway")
        }

        // Decapsulate the Target response into a HTTPURLResponse
        let message = try session.decapsulate(encoded: [UInt8](data))
        return (Data(message.payload),
                HTTPURLResponse(url: request.url!,
                                statusCode: Int(message.statusCode),
                                httpVersion: "HTTP/1.1",
                                headerFields: message.headers)!)
    }
}
