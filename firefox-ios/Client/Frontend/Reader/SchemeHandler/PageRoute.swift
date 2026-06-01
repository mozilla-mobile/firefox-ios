// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import WebEngine

/// Serves the readermode page at `readermode://app/page?url=<encoded-article-url>`.
final class PageRoute: TinyRoute {
    // MARK: - Test-only
    // ReadabilityService().extract() creates a Tab, attaches a ReaderMode content script,
    // loads the URL in a hidden WKWebView, and waits for Readability.js to send a result.
    // None of that would work in the unit test runner.
    // This closure lets tests provide a fake extraction result or throw a controlled error.
    typealias Extractor = @Sendable (URL, ReaderModeCache, Profile) async throws -> ReadabilityResult

    private let cache: ReaderModeCache
    private let profile: Profile
    private let extractor: Extractor

    init(cache: ReaderModeCache,
         profile: Profile,
         extractor: @escaping Extractor = { url, cache, profile in
        try await ReadabilityService().extract(url, cache: cache, with: profile) // default value
    }) {
        self.cache = cache
        self.profile = profile
        self.extractor = extractor
    }

    // needed to conform to TinyRoute
    func handle(url: URL, components: URLComponents) async throws -> TinyHTTPReply? {
        let articleURL = try extractArticleURL(from: components)

        do {
            let result = try await fetchOrExtract(articleURL: articleURL)
            return try await renderReaderPage(url: url, result: result)
        } catch {
            return try buildErrorReply(url: url)
        }
    }

    // MARK: - Result acquisition

    private func fetchOrExtract(articleURL: URL) async throws -> ReadabilityResult {
        if let cached = try? cache.get(articleURL) {
            return cached
        }
        return try await extractor(articleURL, cache, profile)
    }

    // MARK: - Rendering

    private func renderReaderPage(url: URL, result: ReadabilityResult) async throws -> TinyHTTPReply {
        let html = try await MainActor.run { [profile] () throws -> String in
            let style = Self.readerModeStyle(from: profile.prefs)
            guard let rendered = ReaderModeUtils.generateReaderContent(
                result,
                initialStyle: style
            ) else {
                throw TinyRouterError.badResponse
            }
            return rendered
        }

        guard let body = html.data(using: .utf8) else {
            throw TinyRouterError.badResponse
        }
        return try buildSuccessReply(url: url, body: body)
    }

    @MainActor
    private static func readerModeStyle(from prefs: Prefs) -> ReaderModeStyle {
        if let dict = prefs.dictionaryForKey(PrefsKeys.ReaderModeProfileKeyStyle),
           let style = ReaderModeStyle(windowUUID: nil, dict: dict) {
            return style
        }
        let style = ReaderModeStyle.defaultStyle()
        style.theme = ReaderModeTheme.preferredTheme(window: nil)
        return style
    }

    // MARK: - URL parsing
    private func extractArticleURL(from components: URLComponents) throws -> URL {
        guard let raw = components.queryItems?.first(where: { $0.name == "url" })?.value else {
            throw TinyRouterError.missingParam("url")
        }
        guard let parsed = URL(string: raw), parsed.isWebPage(includeDataURIs: false) else {
            throw TinyRouterError.invalidParam("url", raw)
        }

        return parsed
    }

    // MARK: - Response builders

    func buildSuccessReply(url: URL, body: Data) throws -> TinyHTTPReply {
        // Single-line CSP since HTTPURLResponse drops multi-line header values.
        let origin = "\(ReaderModeSchemeHandler.scheme)://\(ReaderModeSchemeHandler.host)"
        let csp = "default-src 'none'; "
        + "img-src *; "
        + "style-src 'unsafe-inline' \(origin); "
        + "font-src \(origin)"
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "text/html; charset=utf-8",
                "Content-Security-Policy": csp
            ]
        ) else {
            throw TinyRouterError.badResponse
        }
        return TinyHTTPReply(httpResponse: response, body: body)
    }

    // It would be nice to have a standard way of displaying error pages, but it seems that
    // mobile Firefox does not have this yet (?)
    func buildErrorReply(url: URL) throws -> TinyHTTPReply {
        let errorString: String = .ReaderModeHandlerError
        guard let body = errorString.data(using: .utf8) else {
            throw TinyRouterError.badResponse
        }
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html; charset=utf-8"]
        ) else {
            throw TinyRouterError.badResponse
        }
        return TinyHTTPReply(httpResponse: response, body: body)
    }
}
