// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

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
    // TODO: Laurie
    nonisolated(unsafe) static var keyCache = [URL: ([UInt8], Date)]()

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

// MARK: GLEAN DEFINITONS TO REMOVE

public typealias HeadersList = [String: String]

/// The interface defining how to send pings.
public protocol PingUploader {
    /**
     * Synchronously upload a ping to a server.
     *
     * @param request the ping upload request, locked within a uploader capability check
     *
     * @param callback used to return the status code of the upload response, so Glean knows whether or not to try again
     */
    func upload(
        request: CapablePingUploadRequest,
        callback: @escaping (UploadResult) -> Void
    )
}

struct PingRequest {
    let documentId: String
    let path: String
    let body: [UInt8]
    let headers: [String: String]
    let uploaderCapabilities: [String]
}

public struct PingUploadRequest {
    let documentId: String
    public let url: String
    public let data: [UInt8]
    public let headers: HeadersList
    let uploaderCapabilities: [String]

    init(request: PingRequest, endpoint: String) {
        self.documentId = request.documentId
        self.url = endpoint + request.path
        self.data = request.body
        self.headers = request.headers
        self.uploaderCapabilities = request.uploaderCapabilities
    }
}

public struct CapablePingUploadRequest {
    private let request: PingUploadRequest

    init(_ request: PingUploadRequest) {
        self.request = request
    }

    /**
     * Checks to see if the requested uploader capabilites are within the advertised uploader capabilities.
     *
     *@param uploaderCapabilities an array of Strings representing the uploader's supported capabilities.
     */
    public func capable(_ uploaderCapabilities: [String]) -> PingUploadRequest? {
        // Check to see if the request's uploader capabilites are all satisfied by the
        // uploader capabilites that were advertised by the uploader via the
        // `uploaderCapabilities` parameter to this function.
        if self.request.uploaderCapabilities.allSatisfy(uploaderCapabilities.contains) {
            return self.request
        }
        return nil
    }
}
