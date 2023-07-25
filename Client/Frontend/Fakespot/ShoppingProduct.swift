// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents a parsed product for a URL.
///
/// - Parameters:
///   - id: The product id of the product.
///   - host: The host of a product URL (without www).
///   - topLevelDomain: The top-level domain of a URL.
///   - sitename: The name of a website (without TLD or subdomains).
///   - valid: If the product is valid or not.
struct Product {
    let id: String
    let host: String
    let topLevelDomain: String
    let sitename: String
}

/// Class for working with the products shopping API,
/// with helpers for parsing the product from a URL
/// and querying the shopping API for information on it.
class ShoppingProduct: FeatureFlaggable {
    private let url: URL
    private let nimbusFakespotFeatureLayer: NimbusFakespotFeatureLayerProtocol

    /// Creates a product.
    /// - Parameter url: URL to get the product info from.
    init(url: URL, nimbusFakespotFeatureLayer: NimbusFakespotFeatureLayerProtocol = NimbusFakespotFeatureLayer()) {
        self.url = url
        self.nimbusFakespotFeatureLayer = nimbusFakespotFeatureLayer
    }

    var isFakespotFeatureEnabled: Bool {
        guard featureFlags.isFeatureEnabled(.fakespotFeature, checking: .buildOnly) else { return false }
        return true
    }

    var isShoppingCartButtonVisible: Bool {
        return product != nil && isFakespotFeatureEnabled
    }

    /// Gets a Product from a URL.
    /// - Returns: Product information parsed from the URL.
    lazy var product: Product? = {
        guard let host = url.host,
              let sitename = url.shortDomain,
              let tld = url.publicSuffix,
              let siteConfig = nimbusFakespotFeatureLayer.getSiteConfig(siteName: sitename),
              siteConfig.validTlDs.contains(tld) else { return nil }

        // Try to find a product id from the pathname.
        guard let id = url.absoluteString.match(siteConfig.productIdFromUrlRegex) else { return nil }

        return Product(id: id, host: host, topLevelDomain: tld, sitename: sitename)
    }()
}
