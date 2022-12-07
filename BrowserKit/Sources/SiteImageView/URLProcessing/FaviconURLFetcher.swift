// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Fuzi

/// Scrapes the HTML at a given site for images
protocol FaviconURLFetcher {

    /// Scraptes the HTML at the given url for a favicon image
    /// - Parameter siteURL: The web address we want to retrieve the favicon for
    /// - Parameter completion: Returns a result type of either a URL on success or a SiteImageError on failure
    func fetchFaviconURL(siteURL: URL, completion: @escaping ((Result<URL, SiteImageError>) -> Void))
}

struct DefaultFaviconURLFetcher: FaviconURLFetcher {

    private let network: NetworkRequest

    init(network: NetworkRequest = HTMLDataRequest()) {
        self.network = network
    }

    func fetchFaviconURL(siteURL: URL, completion: @escaping ((Result<URL, SiteImageError>) -> Void)) {
        network.fetchDataForURL(siteURL) { result in
            switch result {
            case let .success(data):
                self.processHTMLDocument(siteURL: siteURL,
                                         data: data,
                                         completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func processHTMLDocument(siteURL: URL, data: Data, completion: @escaping ((Result<URL, SiteImageError>) -> Void)) {
        guard let root = try? HTMLDocument(data: data) else {
            completion(.failure(.invalidHTML))
            return
        }

        var reloadURL: URL?

        // Check if we need to redirect
        for meta in root.xpath("//head/meta") {
            if let refresh = meta["http-equiv"], refresh == "Refresh",
               let content = meta["content"],
               let index = content.range(of: "URL="),
               let url = URL(string: String(content[index.upperBound...])) {
                reloadURL = url
            }
        }

        // Redirect if needed
        if let reloadURL = reloadURL {
            fetchFaviconURL(siteURL: reloadURL, completion: completion)
            return
        }

        // Search for the first reference to an icon
        for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
            guard let href = link["href"] else { continue }

            if let faviconURL = URL(string: siteURL.absoluteString + "/" + href) {
                completion(.success(faviconURL))
                return
            }
        }

        // Fallback to the favicon at the root of the domain
        // This is a fall back because it's generally low res
        if let faviconURL = URL(string: siteURL.absoluteString + "/favicon.ico") {
            completion(.success(faviconURL))
            return
        }

        completion(.failure(.noFaviconFound))
        return
    }
}
