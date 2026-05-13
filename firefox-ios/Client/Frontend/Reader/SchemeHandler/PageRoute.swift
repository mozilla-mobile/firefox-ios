// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import WebEngine

/// Serves the reader-mode page document at `readermode://app/page?url=<encoded-article-url>`.
///
/// The cache is purely an optimization. On hit, we render the cached `ReadabilityResult`
/// straight away. On miss, we run `ReadabilityService.extract(...)` inline — a hidden
/// WKWebView loads the article URL, runs Readability.js, and returns the parsed result.
/// That result is cached for next time and rendered as the response to this same request.
/// If extraction fails or times out, a small inline error page is served with a "Load
/// Original" link to the source URL.
final class PageRoute: TinyRoute {
    private let cache: ReaderModeCache
    private let profile: Profile

    init(cache: ReaderModeCache, profile: Profile) {
        self.cache = cache
        self.profile = profile
    }

    func handle(url: URL, components: URLComponents) async throws -> TinyHTTPReply? {
        let articleURL = try extractArticleURL(from: components)

        do {
            let result = try await fetchOrExtract(articleURL: articleURL)
            return try await renderReaderPage(url: url, result: result)
        } catch {
            return try buildErrorReply(url: url, originalURL: articleURL)
        }
    }

    // MARK: - Result acquisition

    private func fetchOrExtract(articleURL: URL) async throws -> ReadabilityResult {
        if let cached = try? cache.get(articleURL) {
            return cached
        }
        // Cache miss: extract inline. `ReadabilityService.extract` writes the successful
        // result to the supplied cache as a side-effect, so subsequent loads hit the
        // cache directly.
        return try await ReadabilityService().extract(articleURL, cache: cache, with: profile)
    }

    // MARK: - Rendering

    private func renderReaderPage(url: URL, result: ReadabilityResult) async throws -> TinyHTTPReply {
        // `ReaderModeStyle` is a MainActor-isolated class and
        // `ReaderModeUtils.generateReaderContent` is MainActor-isolated. Hop briefly for
        // the style lookup + template substitution.
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
        return try buildReply(url: url, body: body)
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
        guard let parsed = URL(string: raw), parsed.isWebPage() else {
            throw TinyRouterError.invalidParam("url", raw)
        }
        return parsed
    }

    // MARK: - Response builders

    private func buildReply(url: URL, body: Data) throws -> TinyHTTPReply {
        // CSP mirrors `ReaderModeHandlers.generateHtmlFor` but targets our scheme + host
        // instead of `http://localhost:*`. Inline styles/scripts are allowed because the
        // Reader template embeds the readability result inline; images come from anywhere
        // since articles routinely link off-origin.
        let origin = "\(ReaderModeSchemeHandler.scheme)://\(ReaderModeSchemeHandler.host)"
        let csp = """
            default-src 'none';
            img-src *;
            style-src 'unsafe-inline' \(origin);
            font-src \(origin);
            script-src 'unsafe-inline' \(origin);
        """
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

    private func buildErrorReply(url: URL, originalURL: URL) throws -> TinyHTTPReply {
        let safeHref = Self.htmlEscape(originalURL.absoluteString)
        let failureMessage = Self.htmlEscape(String.ReaderModeHandlerPageCantDisplay)
        let loadOriginalLabel = Self.htmlEscape(String.ReaderModeHandlerLoadOriginalPage)

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>\(failureMessage)</title>
          <style>
            body { font-family: -apple-system, sans-serif; max-width: 600px; margin: 40px auto; padding: 0 16px; color: #333; line-height: 1.5; }
            @media (prefers-color-scheme: dark) {
              body { background: #1a1a1a; color: #e8e8e8; }
              a { color: #6fb3ff; }
            }
            h2 { font-weight: 600; }
            a { color: #0066cc; }
          </style>
        </head>
        <body>
          <h2>\(failureMessage)</h2>
          <p><a href="\(safeHref)">\(loadOriginalLabel)</a></p>
        </body>
        </html>
        """

        guard let body = html.data(using: .utf8) else {
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

    private static func htmlEscape(_ s: String) -> String {
        return s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
