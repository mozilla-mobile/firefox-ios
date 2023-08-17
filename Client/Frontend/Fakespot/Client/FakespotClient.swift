// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Protocol representing the FakespotClientType, which defines two asynchronous methods for fetching product analysis data and product ad data.
protocol FakespotClientType {
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData
    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsData]
}

/// An enumeration representing different environments for the Fakespot client.
enum FakespotEnvironment {
    case staging
    case prod

    /// Returns the API analysisEndpoint URL based on the selected environment.
    var analysisEndpoint: URL? {
        switch self {
        case .staging:
            return URL(string: "https://staging.trustwerty.com/api/v1/fx/analysis")
        case .prod:
            return nil
        }
    }

    /// Returns the API ad endpoint URL based on the selected environment.
    var adEndpoint: URL? {
        switch self {
        case .staging:
            return URL(string: "https://staging-affiliates.fakespot.io/v1/fx/sp_search")
        case .prod:
            return nil
        }
    }

    /// Returns the configuration URL based on the selected environment.
    var config: URL? {
        switch self {
        case .staging:
            return URL(string: "https://stage.ohttp-gateway.nonprod.webservices.mozgcp.net/ohttp-configs")
        case .prod:
            return nil
        }
    }

    /// Returns the relay URL based on the selected environment.
    var relay: URL? {
        switch self {
        case .staging:
            return URL(string: "https://mozilla-ohttp-relay-test.edgecompute.app/")
        case .prod:
            return nil
        }
    }
}

/// Struct FakeSpotClient conforms to the FakespotClientType protocol and provides real network implementations for fetching product analysis data and product ad data.
struct FakespotClient: FakespotClientType {
    private var environment: FakespotEnvironment

    init(environment: FakespotEnvironment) {
        self.environment = environment
    }

    /// Error enum for FakeSpotClient errors, including invalid URL.
    enum FakeSpotClientError: Error {
        case invalidURL
    }

    /// Asynchronous method to fetch product analysis data from a remote server.
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData {
        // Define the API endpoint URL
        guard let endpointURL = environment.analysisEndpoint else {
            throw FakeSpotClientError.invalidURL
        }

        // Prepare the request body
        let requestBody = [
            "product_id": productId,
            "website": website
        ]

        // Perform the async API request and get the data
        return try await fetch(ProductAnalysisData.self, url: endpointURL, requestBody: requestBody)
    }

    /// Asynchronous method to fetch product ad data from a remote server.
    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsData] {
        // Define the API endpoint URL
        guard let endpointURL = environment.adEndpoint  else {
            throw FakeSpotClientError.invalidURL
        }

        // Prepare the request body
        let requestBody = [
            "website": website,
            "product_id": productId
        ]

        // Perform the async API request and get the data
        return try await fetch([ProductAdsData].self, url: endpointURL, requestBody: requestBody)
    }

    /// Asynchronous method to perform the API request and decode the response data.
    private func fetch<T: Decodable>(_ type: T.Type, url: URL, requestBody: [String: Any]) async throws -> T {
        // Serialize the request body to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        guard
            let config = environment.config,
            let relay = environment.relay
        else {
            throw FakeSpotClientError.invalidURL
        }

        // Create an instance of OhttpManager with the staging configuration
        let manager = OhttpManager(configUrl: config, relayUrl: relay)
        // Perform the API request using OhttpManager and get the response data
        let (data, response): (Data, URLResponse) = try await manager.data(for: request)

        // Check if the response status code indicates success (200)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil)
        }

        // Decode the response data and return the result
        return try JSONDecoder().decode(type, from: data)
    }
}
