// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/**
 Represents a parsed product for a URL.

 - Parameter id: The product id of the product.
 - Parameter host: The host of a product URL (without www).
 - Parameter tld: The top-level domain of a URL.
 - Parameter sitename: The name of a website (without TLD or subdomains).
 - Parameter valid: If the product is valid or not.
 */
struct Product {
    let id: String
    let host: String
    let tld: String
    let sitename: String
}

/**
 Class for working with the products shopping API,
 with helpers for parsing the product from a URL
 and querying the shopping API for information on it.
 */
class ShoppingProduct: FeatureFlaggable {
    private let fakespotFeature = FxNimbus.shared.features.fakespotFeature.value()
    private let url: URL

    /*
     Creates a product.
     - Parameter url: URL to get the product info from.
     */
    init(url: URL) {
        self.url = url
    }

    private var isFakespotFeatureEnabled: Bool {
        guard featureFlags.isFeatureEnabled(.fakespotFeature, checking: .buildOnly) else { return false }
        return true
    }

    var isShoppingCartButtonVisible: Bool {
        return product != nil && isFakespotFeatureEnabled
    }

    /**
     Gets a Product from a URL.
     - Returns: Product information parsed from the URL.
     */

    var product: Product? {
        guard let host = url.host, !host.isEmpty else { return nil }
        guard let sitename = url.shortDomain, !sitename.isEmpty else { return nil }
        guard let tld = url.publicSuffix else { return nil }
         // Check if sitename is one the API has products for
        guard let siteConfig = fakespotFeature.config[sitename] else { return nil }
        // Check if API has products for this TLD
        guard siteConfig.validTlDs.contains(tld) else { return nil }

        // Try to find a product id from the pathname.
        let matches = url.absoluteString.match(siteConfig.productIdFromUrlRegex)
        guard let id = matches.first else { return nil }

        return Product(id: id, host: host, tld: tld, sitename: sitename)
    }
}
