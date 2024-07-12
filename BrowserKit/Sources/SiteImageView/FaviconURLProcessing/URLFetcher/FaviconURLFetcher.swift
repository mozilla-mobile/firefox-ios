// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Fuzi

/// Scrapes the HTML at a given site for images
protocol FaviconURLFetcher {
    /// Scrapes the HTML at the given url for a favicon image
    /// - Parameter siteURL: The web address we want to retrieve the favicon for
    /// - Parameter completion: Returns a result type of either a URL on success or a SiteImageError on failure
    func fetchFaviconURL(siteURL: URL) async throws -> URL
}

struct DefaultFaviconURLFetcher: FaviconURLFetcher {
    private let network: HTMLDataRequest

    init(network: HTMLDataRequest = DefaultHTMLDataRequest()) {
        self.network = network
    }

    func fetchFaviconURL(siteURL: URL) async throws -> URL {
        do {
            let data = try await network.fetchDataForURL(siteURL)
            let url = try await self.processHTMLDocument(siteURL: siteURL,
                                                         data: data)
            return url
        } catch {
            throw error
        }
    }

    private func processHTMLDocument(siteURL: URL, data: Data) async throws -> URL {
        guard let root = try? HTMLDocument(data: data) else {
            throw SiteImageError.invalidHTML
        }

        var reloadURL: URL?

        // Check if we need to redirect
        for meta in root.xpath("//head/meta") {
            if let refresh = meta["http-equiv"], refresh == "Refresh",
               let content = meta["content"],
               let index = content.range(of: "URL="),
               let url = URL(string: String(content[index.upperBound...]), invalidCharacters: false) {
                reloadURL = url
            }
        }

        // Redirect if needed
        if let reloadURL = reloadURL {
            return try await fetchFaviconURL(siteURL: reloadURL)
        }

        // Search for the first reference to an icon
        for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
            guard let href = link["href"] else { continue }
            if let faviconURL = URL(string: href, relativeTo: siteURL) {
                return faviconURL
            }
        }

        // Fallback to the favicon at the root of the domain
        // This is a fallback because it's generally low res
        if let faviconURL = siteURL.faviconUrl() {
            return faviconURL
        }

        throw SiteImageError.noFaviconFound
    }
}
