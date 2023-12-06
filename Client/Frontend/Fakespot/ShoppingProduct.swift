// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Represents a parsed product for a URL.
///
/// - Parameters:
///   - id: The product id of the product.
///   - host: The host of a product URL (without www).
///   - topLevelDomain: The top-level domain of a URL.
///   - sitename: The name of a website (without TLD or subdomains).
///   - valid: If the product is valid or not.
struct Product: Equatable {
    let id: String
    let host: String
    let topLevelDomain: String
    let sitename: String
}

/// Class for working with the products shopping API,
/// with helpers for parsing the product from a URL
/// and querying the shopping API for information on it.
class ShoppingProduct: FeatureFlaggable, Equatable {
    private let url: URL
    private let nimbusFakespotFeatureLayer: NimbusFakespotFeatureLayerProtocol
    private let client: FakespotClientType

    /// Initializes a new instance of a product with the provided URL and optional parameters.
    ///
    /// - Parameters:
    ///   - url: The URL to parse the Product instance from.
    ///   - nimbusFakespotFeatureLayer: An optional parameter of type `NimbusFakespotFeatureLayerProtocol`.
    ///                                 It represents the feature layer used for Nimbus Fakespot integration.
    ///   - client: An optional parameter of type `FakeSpotClient`. It represents the client used for communication
    ///             with the FakeSpot service.
    ///
    /// - Note: The `nimbusFakespotFeatureLayer` and `client` parameters are optional and have default values, which means you can
    ///         omit them when calling this initializer in most cases.
    ///
    /// - Important: Make sure to provide a valid `url`. If the URL is invalid or the server cannot be reached, the product
    ///              information may not be fetched successfully.
    init(
        url: URL,
        nimbusFakespotFeatureLayer: NimbusFakespotFeatureLayerProtocol = NimbusFakespotFeatureLayer(),
        client: FakespotClientType
    ) {
        self.url = url
        self.nimbusFakespotFeatureLayer = nimbusFakespotFeatureLayer
        self.client = client
    }

    var isFakespotFeatureEnabled: Bool {
        guard featureFlags.isFeatureEnabled(.fakespotFeature, checking: .buildOnly) else { return false }
        return true
    }

    var isProductBackInStockFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.fakespotBackInStock, checking: .buildOnly)
    }

    var isProductAdsFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.fakespotProductAds, checking: .buildOnly)
    }

    var isShoppingButtonVisible: Bool {
        return product != nil && isFakespotFeatureEnabled
    }

    /// Gets a list of supported top-level domain (TLD) websites.
    /// - Returns: An array of supported TLD websites or `nil` if no valid product is available.
    var supportedTLDWebsites: [String]? {
        guard let product = product else { return nil }
        let config = nimbusFakespotFeatureLayer.config

        let validWebsites = config.compactMap { (key, value) in
            value.validTlDs.contains(product.topLevelDomain) ? key : nil
        }

        return validWebsites
    }

    /// Gets a Product from a URL.
    /// - Returns: Product information parsed from the URL.
    lazy var product: Product? = {
        guard let host = url.baseDomain,
              let sitename = url.shortDomain,
              let tld = url.publicSuffix,
              let siteConfig = nimbusFakespotFeatureLayer.getSiteConfig(siteName: sitename),
              siteConfig.validTlDs.contains(tld),
              let id = url.absoluteString.match(siteConfig.productIdFromUrlRegex)
        else { return nil }

        return Product(id: id, host: host, topLevelDomain: tld, sitename: sitename)
    }()

    /// Fetches the analysis data for a specific product.
    ///
    /// - Parameters:
    ///   - maxRetries: The number of retry attempts to fetch the data in case of failures. Default is 3.
    ///   - retryTimeout: The time interval (in milliseconds) to wait between retry attempts. Default is 100 milliseconds.
    /// - Returns: An instance of `ProductAnalysisData` containing the analysis data for the product, or `nil` if the product is not available.
    /// - Throws: An error of type `Error` if there's an issue during the data fetching process, even after the specified number of retries.
    /// - Note: This function is an asynchronous operation and should be called within an asynchronous context using `await`.
    ///
    func fetchProductAnalysisData(maxRetries: Int = 3, retryTimeout: Int = 100) async throws -> ProductAnalysisResponse? {
        guard let product else { return nil }

        // Perform 'retryCount' attempts, and retry on 500 failure:
        for failCount in 0..<maxRetries {
            do {
                // Attempt to perform the asynchronous 'fetch(_ type:, url:, requestBody:)' operation.
                // If it succeeds, the 'return' statement will immediately exit the function,
                // returning the loaded 'ProductAnalysisData'.
                return try await client.fetchProductAnalysisData(productId: product.id, website: product.host)
            } catch {
                // If 500 error occurs during the attempt, we use 'continue'
                // to go back to the beginning of the loop and try again.
                // This means we will retry the 'fetch(_ type:, url:, requestBody:)' operation.
                if case OhttpError.RelayFailed = error {
                    let backOff = retryTimeout * Int(pow(2, Double(failCount - 1)))
                    try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * UInt64(backOff))
                    continue
                } else if (error as NSError).code == 500 {
                    let backOff = retryTimeout * Int(pow(2, Double(failCount - 1)))
                    try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * UInt64(backOff))
                    continue
                } else {
                    throw error
                }
            }
        }

        // If the loop completes three attempts and none of them succeed,
        // we reach this point. Here, we make a final attempt (fourth attempt),
        // which throws its error if it fails. If this attempt also fails,
        // the error will be propagated out of the function to the caller.
        return try await client.fetchProductAnalysisData(productId: product.id, website: product.host)
    }

    /// Fetches an array of ads data for a specific product.
    ///
    /// - Returns: An array of `ProductAdsData` containing the ads data for the product, or an empty array if the product is not available or no ads data is found.
    /// - Throws: An error of type `Error` if there's an issue during the data fetching process.
    /// - Note: This function is an asynchronous operation and should be called within an asynchronous context using `await`.
    ///
    func fetchProductAdsData() async -> [ProductAdsResponse] {
        guard let product else { return [] }
        return (try? await client.fetchProductAdData(productId: product.id, website: product.host)) ?? []
    }

    /// Triggers the analysis of the current product.
    ///
    /// - Returns: An optional `ProductAnalyzeResponse.AnalysisStatus` indicating the status of the analysis, or `nil` if there's no product available.
    /// - Throws: An error of type `Error` if there's an issue triggering the analysis.
    /// - Note: This function is an asynchronous operation and should be called within an asynchronous context using `await`.
    ///
    func triggerProductAnalyze() async throws -> AnalysisStatus? {
        // Ensure that a valid product is available
        guard let product = product else { return nil }

        // Trigger product analysis using the product ID and website
        return try await client.triggerProductAnalyze(productId: product.id, website: product.host).status
    }

    /// Retrieves the analysis status for the current product.
    ///
    /// - Returns: A `ProductAnalysisStatusResponse` containing the analysis status, or `nil` if there's no product available.
    /// - Throws: An error of type `Error` if there's an issue retrieving the analysis status.
    /// - Note: This function is an asynchronous operation and should be called within an asynchronous context using `await`.
    ///
    func getProductAnalysisStatus() async throws -> ProductAnalysisStatusResponse? {
        // Ensure that a valid product is available
        guard let product = product else { return nil }

        // Retrieve the product analysis status using the product ID and website
        return try await client.getProductAnalysisStatus(productId: product.id, website: product.host)
    }

    /// Reports the current product as back in stock.
    ///
    /// This function asynchronously reports the current product as back in stock using the product's ID and website.
    ///
    /// - Returns: A `ReportResponse` containing the result of the reporting operation, or `nil` if there's no product available.
    /// - Throws: An error of type `Error` if there's an issue reporting the product as back in stock.
    /// - Note: This function is an asynchronous operation and should be called within an asynchronous context using `await`.
    ///
    func reportProductBackInStock() async throws -> ReportResponse? {
        // Ensure that a valid product is available
        guard let product = product else { return nil }

        // Report the product as back in stock using the product ID and website
        return try await client.reportProductBackInStock(productId: product.id, website: product.host)
    }

    func reportAdEvent(eventName: String, eventSource: String, aidvs: [String]) async throws -> AdEventsResponse {
        return try await client.reportAdEvent(eventName: eventName, eventSource: eventSource, aidvs: aidvs)
    }

    static func == (lhs: ShoppingProduct, rhs: ShoppingProduct) -> Bool {
        return lhs.product == rhs.product
    }
}
