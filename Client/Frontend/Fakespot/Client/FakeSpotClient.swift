// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Protocol representing the FakespotClientType, which defines two asynchronous methods for fetching product analysis data and product ad data.
protocol FakespotClientType {
    /// Fetches product analysis data for a given product ID and website.
    /// - Parameters:
    ///   - productId: The ID of the product to analyze.
    ///   - website: The website associated with the product.
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisResponse

    /// Fetches product ad data for a given product ID and website.
    /// - Parameters:
    ///   - productId: The ID of the product to fetch ad data for.
    ///   - website: The website associated with the product.
    /// - Throws: An error if the operation fails.
    /// - Returns: An array of `ProductAdsResponse` objects containing ad data.
    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsResponse]

    /// Triggers the analysis of a product for a given product ID and website.
    /// - Parameters:
    ///   - productId: The ID of the product to analyze.
    ///   - website: The website associated with the product.
    /// - Throws: An error if the analysis cannot be triggered.
    /// - Returns: A `ProductAnalyzeResponse` indicating the status of the analysis.
    func triggerProductAnalyze(productId: String, website: String) async throws -> ProductAnalyzeResponse

    /// Retrieves the analysis status for a product on a specific website.
    ///
    /// - Parameters:
    ///   - productId: The ID of the product to analyze.
    ///   - website: The website associated with the product.
    /// - Returns: A `ProductAnalysisStatusResponse` containing the analysis status.
    /// - Throws: `FakeSpotClientError.invalidURL` if the API endpoint URL is missing or invalid,
    ///           and any other errors that may occur during the API request.
    func getProductAnalysisStatus(productId: String, website: String) async throws -> ProductAnalysisStatusResponse

    /// Reports a product as back in stock for a given product ID and website asynchronously.
    ///
    /// - Parameters:
    ///   - productId: The ID of the product to analyze.
    ///   - website: The website associated with the product.
    /// - Returns: A `ReportResponse` indicating the result of the back-in-stock report.
    /// - Throws: `FakeSpotClientError.invalidURL` if the API endpoint URL is missing or invalid,
    ///           and any other errors that may occur during the API request.
    func reportProductBackInStock(productId: String, website: String) async throws -> ReportResponse

    /// Reports an advertising event with specified details to the API.
    /// - Parameters:
    ///   - eventName: The name of the advertising event.
    ///   - eventSource: The source of the advertising event.
    ///   - aid: A string representing identifier for the event.
    /// - Returns: An `AdEventsResponse` object containing the response data.
    /// - Throws: `FakeSpotClientError.invalidURL` if the ad recording endpoint URL is invalid or not set.
    func reportAdEvent(eventName: FakespotAdsEvent, eventSource: String, aid: String) async throws -> AdEventsResponse
}

/// An enumeration representing different environments for the Fakespot client.
enum FakespotEnvironment {
    case staging
    case prod

    enum FakespotPath: String {
        case analyze = "/analyze"
        case analysis = "/analysis"
        case analysisStatus = "/analysis_status"
        case report = "/report"
    }

    private var baseURL: String {
        switch self {
        case .staging:
            return "https://staging.trustwerty.com"
        case .prod:
            return "https://trustwerty.com"
        }
    }

    private var apiVersion: String {
        return "/api/v2/fx"
    }

    private func buildURL(path: FakespotPath) -> URL? {
        let urlString = baseURL + apiVersion + path.rawValue
        return URL(string: urlString)
    }

    /// Returns the API analyze endpoint URL based on the selected environment.
    var analyzeEndpoint: URL? {
        buildURL(path: .analyze)
    }

    /// Returns the API analysis endpoint URL based on the selected environment.
    var analysisEndpoint: URL? {
        buildURL(path: .analysis)
    }

    /// Returns the API analysis status endpoint URL based on the selected environment.
    var analysisStatusEndpoint: URL? {
        buildURL(path: .analysisStatus)
    }

    var reportEndpoint: URL? {
        buildURL(path: .report)
    }

    /// Returns the API ad endpoint URL based on the selected environment.
    var adEndpoint: URL? {
        switch self {
        case .staging:
            return URL(string: "https://staging-affiliates.fakespot.io/v1/fx/sp_search")
        case .prod:
            return URL(string: "https://a.fakespot.com/v1/fx/sp_search")
        }
    }

    var adRecordingEndpoint: URL? {
        switch self {
        case .staging:
            return URL(string: "https://staging-partner-ads.fakespot.io/api/v1/fx/events")
        case .prod:
            return URL(string: "https://pe.fakespot.com/api/v1/fx/events")
        }
    }

    /// Returns the configuration URL based on the selected environment.
    var config: URL? {
        switch self {
        case .staging:
            return URL(string: "https://stage.ohttp-gateway.nonprod.webservices.mozgcp.net/ohttp-configs")
        case .prod:
            return URL(string: "https://prod.ohttp-gateway.prod.webservices.mozgcp.net/ohttp-configs")
        }
    }

    /// Returns the relay URL based on the selected environment.
    var relay: URL? {
        switch self {
        case .staging:
            return URL(string: "https://mozilla-ohttp-dev.fastly-edge.com/")
        case .prod:
            return NimbusFakespotFeatureLayer().relayURL
        }
    }
}

/// Struct FakeSpotClient conforms to the FakespotClientType protocol and provides real network implementations for fetching product analysis data and product ad data.
struct FakespotClient: FakespotClientType {
    private var environment: FakespotEnvironment

    /// Initializes a FakeSpotClient with the specified environment.
    /// - Parameter environment: The environment to use (staging or production).
    init(environment: FakespotEnvironment) {
        self.environment = environment
    }

    /// Error enum for FakeSpotClient errors, including invalid URL.
    enum FakeSpotClientError: Error {
        case invalidURL
    }

    /// Retrieves the analysis status for a product on a specific website.
    func getProductAnalysisStatus(productId: String, website: String) async throws -> ProductAnalysisStatusResponse {
        // Define the API endpoint URL
        guard let endpointURL = environment.analysisStatusEndpoint else {
            throw FakeSpotClientError.invalidURL
        }

        // Prepare the request body
        let requestBody = [
            "website": website,
            "product_id": productId
        ]

        // Perform the async API request and get the data
        return try await fetch(ProductAnalysisStatusResponse.self, url: endpointURL, requestBody: requestBody)
    }

    /// Trigger product analyze for a given product ID and website.
    func triggerProductAnalyze(productId: String, website: String) async throws -> ProductAnalyzeResponse {
        // Define the API endpoint URL
        guard let endpointURL = environment.analyzeEndpoint else {
            throw FakeSpotClientError.invalidURL
        }

        // Prepare the request body
        let requestBody = [
            "website": website,
            "product_id": productId
        ]

        // Perform the async API request and get the data
        return try await fetch(ProductAnalyzeResponse.self, url: endpointURL, requestBody: requestBody)
    }

    /// Fetches product analysis data for a given product ID and website.
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisResponse {
        // Define the API endpoint URL
        guard let endpointURL = environment.analysisEndpoint else {
            throw FakeSpotClientError.invalidURL
        }

        // Prepare the request body
        let requestBody = [
            "website": website,
            "product_id": productId
        ]

        // Perform the async API request and get the data
        return try await fetch(ProductAnalysisResponse.self, url: endpointURL, requestBody: requestBody)
    }

    /// Fetches product ad data for a given product ID and website.
    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsResponse] {
        // Define the API endpoint URL
        guard let endpointURL = environment.adEndpoint else {
            throw FakeSpotClientError.invalidURL
        }

        // Prepare the request body
        let requestBody = [
            "website": website,
            "product_id": productId
        ]

        // Perform the async API request and get the data
        return try await fetch([ProductAdsResponse].self, url: endpointURL, requestBody: requestBody)
    }

    /// Reports product back in stock for a given product ID and website.
    func reportProductBackInStock(productId: String, website: String) async throws -> ReportResponse {
        // Define the API endpoint URL
        guard let endpointURL = environment.reportEndpoint else {
            throw FakeSpotClientError.invalidURL
        }

        // Prepare the request body
        let requestBody = [
            "website": website,
            "product_id": productId
        ]

        // Perform the async API request and get the data
        return try await fetch(ReportResponse.self, url: endpointURL, requestBody: requestBody)
    }

    /// Reports an advertising event with specified details to the API
    func reportAdEvent(eventName: FakespotAdsEvent, eventSource: String, aid: String) async throws -> AdEventsResponse {
        // Define the API endpoint URL
        guard let endpointURL = environment.adRecordingEndpoint else {
            throw FakeSpotClientError.invalidURL
        }

        let requestBody: [String: Any]

        switch eventName {
        case .trustedDealsLinkClicked:
            requestBody = [
                "event_name": eventName.rawValue,
                "event_source": eventSource,
                "aid": aid
            ]
        case .trustedDealsImpression, .trustedDealsPlacement:
            requestBody = [
                "event_name": eventName.rawValue,
                "event_source": eventSource,
                "aidvs": [aid]
            ]
        }

        // Perform the async API request and get the data
        return try await fetch(AdEventsResponse.self, url: endpointURL, requestBody: requestBody)
    }

    /// Asynchronous method to perform the API request and decode the response data.
    private func fetch<T: Decodable>(_ type: T.Type, url: URL, requestBody: [String: Any]) async throws -> T {
        // Serialize the request body to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
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
