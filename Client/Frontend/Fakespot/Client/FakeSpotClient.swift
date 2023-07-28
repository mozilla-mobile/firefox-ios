// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FakeSpotClientType {
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData
    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsData]
}

struct MockFakeSpotClient: FakeSpotClientType {
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData {
        try load(ProductAnalysisData.self, filename: "productanalysis-response")
    }

    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsData] {
        try load([ProductAdsData].self, filename: "productadsdata-response")
    }

    private func load<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        let path = Bundle.main.url(forResource: filename, withExtension: "json")!
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(type, from: data)
    }
}

struct StagingFakeSpotClient: FakeSpotClientType {
    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisData {
        // Define the API endpoint URL
        let endpointURL = URL(string: "https://staging-trustwerty.fakespot.io/api/v1/fx/analysis")!

        // Prepare the request body
        let requestBody = [
            "product_id": productId,
            "website": website
        ]

        // Perform the async API request and get the data
        return try await fetch(ProductAnalysisData.self, url: endpointURL, requestBody: requestBody)
    }

    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsData] {
        // Define the API endpoint URL
        let endpointURL = URL(string: "https://staging-affiliates.fakespot.io/v1/fx/sp_search")!

        // Prepare the request body
        let requestBody = [
            "website": website,
            "product_id": productId
        ]

        // Perform the async API request and get the data
        return try await fetch([ProductAdsData].self, url: endpointURL, requestBody: requestBody)
    }

    private func fetch<T: Decodable>(_ type: T.Type, url: URL, requestBody: [String: Any]) async throws -> T {
        // Serialize the request body to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Perform the async API request using URLSession
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check if the response status code indicates success (200)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil)
        }

        return try JSONDecoder().decode(type, from: data)
    }
}
