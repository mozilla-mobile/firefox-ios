// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import WebEngine
import WebKit

/// `ReaderModeSchemeHandler` defines a custom URL scheme handler for a `WKWebView` that
/// serves reader-mode pages and their assets. It replaces the legacy GCDWebServer-based
/// reader-mode routes.
///
/// Request flow
/// ------------
/// 1. The browser navigates a tab to `readermode://app/...`.
///
/// 2. WebKit detects the `readermode://` scheme and creates a `WKURLSchemeTask`.
///
/// 3. WebKit calls `ReaderModeSchemeHandler.webView(_:start:)` passing in the task.
///
/// 4. The scheme handler:
///        - reads the URL from `urlSchemeTask.request`
///        - validates that the URL uses the correct scheme and host (`readermode` and `app`)
///        - forwards the URL to `router.route(_:)` (TinyRouter)
///
/// 5. TinyRouter chooses a route handler based on the path. As the migration progresses
///    the registered routes will be:
///        - `/app/page`         -> `PageRoute`
///        - `/app/page-exists`  -> (future)
///        - `/app/styles/...`   -> (future, static)
///        - `/app/fonts/...`    -> (future, static)
///
/// 6. `send(_:for:to:)` converts the `TinyHTTPReply` into an `HTTPURLResponse` and body
///    and completes the `WKURLSchemeTask`.
///
/// 7. WebKit renders the response in the tab.
final class ReaderModeSchemeHandler: NSObject, WKURLSchemeHandler {
    // These are plain string constants and need to be readable from non-MainActor contexts
    // (e.g. `PageRoute.buildReply`, which constructs the CSP off the main actor). The class
    // itself is @MainActor by virtue of conforming to `WKURLSchemeHandler`, which would
    // otherwise propagate isolation to these statics.

    /// The custom scheme this handler is responsible for.
    nonisolated static let scheme = "readermode"

    /// The host this handler expects for all reader-mode requests.
    nonisolated static let host = "app"

    /// Canonical base URL for the reader page. Callers that need to construct a reader-mode
    /// URL (e.g. `URL.encodeReaderModeURL(_:)`) pass this in place of the legacy
    /// `WebServer.sharedInstance.baseReaderModeURL()`.
    nonisolated static let baseURL = "readermode://app/page"

    private let normalRouter: TinyRouter
    private let privateRouter: TinyRouter
    private let logger: Logger
    private var requestTasks = [ObjectIdentifier: Task<Void, Never>]()

    init(profile: Profile,
         logger: Logger = DefaultLogger.shared) {
        // Two routers, picked per request based on the WKWebView's data store (see
        // `webView(_:start:)`). This ensures private-mode tabs never read from or write
        // to the disk cache, even though BrowserKit's `DefaultWKEngineConfigurationProvider`
        // shares one `WKWebViewConfiguration` between normal and private modes.
        //
        // `StaticFileRoute` is the same one Translations uses — given the path it strips
        // the leading slash, separates the resource name + extension, and looks the file up
        // via `Bundle.main.url(forResource:withExtension:)`. That covers the legacy paths
        // `Reader.html` already references (`/reader-mode/styles/Reader.css` and
        // `/reader-mode/fonts/*.otf`) without any template edits.
        self.normalRouter = TinyRouter()
            .register("page", PageRoute(cache: DiskReaderModeCache.shared, profile: profile))
            .setDefault(StaticFileRoute())
        self.privateRouter = TinyRouter()
            .register("page", PageRoute(cache: MemoryReaderModeCache.shared, profile: profile))
            .setDefault(StaticFileRoute())
        self.logger = logger
        super.init()
    }

    /// Validates incoming requests and forwards them to the router.
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let id = ObjectIdentifier(urlSchemeTask)
        let isPrivate = !webView.configuration.websiteDataStore.isPersistent
        let router = isPrivate ? privateRouter : normalRouter
        let requestTask = Task { @MainActor in
            defer { requestTasks[id] = nil }
            do {
                let url = try validateRequest(urlSchemeTask)
                try Task.checkCancellation()
                let reply = try await router.route(url)
                try Task.checkCancellation()
                try send(reply, for: url, to: urlSchemeTask)
            } catch is CancellationError {
                self.logger.log("Reader-mode scheme task cancelled.",
                                level: .debug,
                                category: .library)
            } catch {
                urlSchemeTask.didFailWithError(mapError(error))
            }
        }
        requestTasks[id] = requestTask
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let id = ObjectIdentifier(urlSchemeTask)
        requestTasks[id]?.cancel()
        requestTasks[id] = nil
    }

    /// Bridges a `TinyHTTPReply` into the `WKURLSchemeTask` callbacks.
    private func send(_ reply: TinyHTTPReply, for url: URL, to task: WKURLSchemeTask) throws {
        guard let httpResponse = reply.httpResponse else {
            throw TinyRouterError.badResponse
        }
        task.didReceive(httpResponse)
        task.didReceive(reply.body)
        task.didFinish()
    }

    /// Normalizes any thrown `Error` into a `TinyRouterError`.
    private func mapError(_ error: Error) -> TinyRouterError {
        if let tinyError = error as? TinyRouterError {
            return tinyError
        }
        return .unknown(String(describing: error))
    }

    /// Validates an incoming request and returns a well-formed URL,
    /// or throws a typed error if the request is not acceptable.
    private func validateRequest(_ task: WKURLSchemeTask) throws -> URL {
        guard let url = task.request.url else { throw TinyRouterError.badURL }

        guard url.scheme == Self.scheme else {
            throw TinyRouterError.unsupportedScheme(expected: Self.scheme, found: url.scheme)
        }

        guard url.host == Self.host else {
            throw TinyRouterError.unsupportedHost(expected: Self.host, found: url.host)
        }

        return url
    }
}
