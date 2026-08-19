/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Performs Oblivious HTTP round-trips via a Gateway and Relay.
///
/// This is an actor rather than a class because callers drive it concurrently:
/// each Glean ping upload runs in its own task. Isolation protects the key cache
/// below, and keeps `OhttpSession` creation in `data(for:)` from overlapping.
public actor OhttpManager {
    // The OhttpManager communicates with the relay and key server using
    // URLSession.shared.data unless an alternative networking method is
    // provided with this signature.
    public typealias NetworkFunction = (_: URLRequest) async throws -> (Data, URLResponse)

    // Cache of Gateway encryption keys, alongside the time each was stored so
    // staleness can be evaluated on read. Stale entries are ignored, and on
    // Gateway errors the key used is purged and retrieved again at the next
    // network attempt.
    private var keyCache = [URL: (key: [UInt8], storedAt: Date)]()

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

    /// Returns the cached key when one is present and still within `ttl`,
    /// dropping it when stale. `nil` means the caller should fetch a fresh key.
    func cachedKey(for gatewayConfigUrl: URL, ttl: TimeInterval) -> [UInt8]? {
        guard let entry = keyCache[gatewayConfigUrl] else { return nil }

        guard Date() < entry.storedAt + ttl else {
            keyCache.removeValue(forKey: gatewayConfigUrl)
            return nil
        }

        return entry.key
    }

    func store(key: [UInt8], for gatewayConfigUrl: URL) {
        keyCache[gatewayConfigUrl] = (key: key, storedAt: Date())
    }

    /// Purges a key so the next network attempt retrieves a fresh one, which is
    /// how Gateway errors are recovered from.
    func invalidateKey(for gatewayConfigUrl: URL) {
        keyCache.removeValue(forKey: gatewayConfigUrl)
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
        if let key = cachedKey(for: gatewayConfigUrl, ttl: ttl) {
            // Cache Hit!
            return key
        }

        let data = try await fetchKey(url: gatewayConfigUrl)
        store(key: data, for: gatewayConfigUrl)

        return data
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Get the encryption keys for Gateway
        let config = try await keyForGateway(gatewayConfigUrl: configUrl,
                                             ttl: TimeInterval(3600))

        // Create an encryption session for a request-response round-trip.
        //
        // Actor isolation is load-bearing here: this synchronous call cannot
        // interleave with another, and the first session created in a process
        // triggers one-time NSS initialization inside the Rust component, which
        // crashes when entered from two threads at once. That holds as long as a
        // single OhttpManager serves the process; a process-wide guarantee needs
        // application-services to initialize NSS up front.
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
            invalidateKey(for: configUrl)
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
