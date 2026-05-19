// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import WebEngine

/// Serves the readermode page document at `readermode://app/page?url=<encoded-article-url>`.
///
/// This initial version validates the incoming URL parameters. Content rendering
/// (cache integration, readability extraction, error pages) will be added in
/// FXIOS-15783.
final class PageRoute: TinyRoute {
    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    // Always erros out for now, will actually handle in next PR
    func handle(url: URL, components: URLComponents) async throws -> TinyHTTPReply? {
        _ = try extractArticleURL(from: components)
        throw TinyRouterError.badResponse
    }

    // MARK: - URL parsing

    private func extractArticleURL(from components: URLComponents) throws -> URL {
        guard let raw = components.queryItems?.first(where: { $0.name == "url" })?.value else {
            throw TinyRouterError.missingParam("url")
        }

        guard let parsed = URL(string: raw), parsed.isWebPage() else {
            throw TinyRouterError.invalidParam("url", raw)
        }

        return parsed
    }
}
