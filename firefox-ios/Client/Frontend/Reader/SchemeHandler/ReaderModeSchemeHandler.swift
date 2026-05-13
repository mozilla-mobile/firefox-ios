// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
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
    /// The custom scheme this handler is responsible for.
    static let scheme = "readermode"

    /// The host this handler expects for all reader-mode requests.
    static let host = "app"

    private static let defaultRouter: TinyRouter = {
        TinyRouter()
            .register("page", PageRoute())
    }()

    private let router: TinyRouter
    private let logger: Logger
    private var requestTasks = [ObjectIdentifier: Task<Void, Never>]()

    init(router: TinyRouter = ReaderModeSchemeHandler.defaultRouter,
         logger: Logger = DefaultLogger.shared) {
        self.router = router
        self.logger = logger
        super.init()
    }

    /// Validates incoming requests and forwards them to the router.
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let id = ObjectIdentifier(urlSchemeTask)
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
