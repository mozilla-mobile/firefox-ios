// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Protocol representing the FakeSpotClientType, which defines two asynchronous methods for fetching product analysis data and product ad data.
protocol FakeSpotClientType {
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData
    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsData]
}

/// Struct MockFakeSpotClient conforms to the FakeSpotClientType protocol and provides mocked implementations for fetching product analysis data and product ad data.
struct MockFakeSpotClient: FakeSpotClientType {
    /// Mock implementation for fetching product analysis data using a JSON file.
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData {
        try load(ProductAnalysisData.self, filename: "productanalysis-response")
    }

    /// Mock implementation for fetching product ad data using a JSON file.
    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsData] {
        try load([ProductAdsData].self, filename: "productadsdata-response")
    }

    /// Helper function to load JSON data from a file.
    private func load<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        let path = Bundle.main.url(forResource: filename, withExtension: "json")!
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(type, from: data)
    }
}

/// Struct FakeSpotClient conforms to the FakeSpotClientType protocol and provides real network implementations for fetching product analysis data and product ad data.
struct FakeSpotClient: FakeSpotClientType {
    /// NetworkFunction typealias represents a function that takes a URLRequest and returns Data and URLResponse asynchronously.
    public typealias NetworkFunction = (_: URLRequest) async throws -> (Data, URLResponse)
    /// Private property to hold the network function for performing API requests.
    private var network: NetworkFunction

    /// Initialize FakeSpotClient with a custom network function.
    init(network: @escaping NetworkFunction) {
        self.network = network
    }

    /// Error enum for FakeSpotClient errors, including invalid URL.
    enum FakeSpotClientError: Error {
        case invalidURL
    }

    /// Asynchronous method to fetch product analysis data from a remote server.
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData {
        // Define the API endpoint URL
        guard let endpointURL = URL(string: "https://staging.trustwerty.com/api/v1/fx/analysis") else {
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
        guard let endpointURL = URL(string: "https://staging-affiliates.fakespot.io/v1/fx/sp_search") else {
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

        // Perform the API request using the network function and get the response data
        let (data, response): (Data, URLResponse) = try await network(request)

        // Check if the response status code indicates success (200)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil)
        }

        // Decode the response data and return the result
        return try JSONDecoder().decode(type, from: data)
    }
}

/// Extension for FakeSpotClient to provide a static staging instance with a custom network function.
extension FakeSpotClient {
    /// Static property representing a staging instance of FakeSpotClient using a custom network function.
    static let staging: FakeSpotClient = {
        FakeSpotClient { @Sendable request in
            // Define the configuration and relay URLs for the staging instance
            let config = URL(string: "https://stage.ohttp-gateway.nonprod.webservices.mozgcp.net/ohttp-configs")!
            let relay = URL(string: "https://mozilla-ohttp-relay-test.edgecompute.app/")!
            // Create an instance of OhttpManager with the staging configuration
            let staging = OhttpManager(configUrl: config, relayUrl: relay)
            // Perform the API request using OhttpManager and get the response data
            return try await staging.data(for: request)
        }
    }()
}
