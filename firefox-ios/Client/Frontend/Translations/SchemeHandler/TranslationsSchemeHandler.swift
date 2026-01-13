// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Foundation
import WebKit

/// `TranslationsSchemeHandler` defines a custom URL scheme handler for a `WKWebView`.
/// It allows the JavaScript side of the translations engine to communicate with the
/// native iOS components by making network requests to `translations://`.
///
/// The following summarizes how a request moves from JavaScript through WebKit to
/// `TranslationsSchemeHandler` and back.
///
/// Request flow
/// ------------
/// 1. JavaScript calls `fetch("translations://app/...")`
///
/// 2. WebKit detects the `translations://` scheme and creates a `WKURLSchemeTask`.
///
/// 3. WebKit calls `TranslationsSchemeHandler.webView(_:start:)` passing in the task.
///
/// 4. The scheme handler:
///        - reads the URL from `urlSchemeTask.request`
///        - validates that the URL uses the correct scheme and host (i.e. `translations` and `app`)
///        - forwards the URL to `router.route(_:)` (TinyRouter)
///
/// 5. TinyRouter chooses a route handler based on the path:
///        - `/app/models`        -> `ModelsRoute`
///        - `/app/models-buffer` -> `ModelsRoute`
///        - `/app/translator`    -> `TranslatorRoute`
///        - fallback `/app/...`  -> `StaticFileRoute` (default fallback)
///    and returns a `TinyHTTPReply` containing status, headers, and body data.
///
/// 6. `send(_:for:to:)` converts the `TinyHTTPReply` into:
///        - an `HTTPURLResponse`
///        - a body (`Data`)
///    and completes the `WKURLSchemeTask`.
///
/// 7. WebKit resolves (or rejects) the original JavaScript `fetch()` promise.
final class TranslationsSchemeHandler: NSObject, WKURLSchemeHandler {
    /// The custom scheme this handler is responsible for.
    static let scheme = "translations"

    /// The host this handler expects for all translations requests.
    static let host = "app"

    /// TinyRouter instance used to dispatch all `translations://app/...` paths.
    ///
    /// Registered routes:
    /// - `models-buffer`: fetches model binary blobs.
    /// - `models`: fetches model metadata.
    /// - `translator`: fetches the translator WASM/binary.
    /// - default: serves static files such as the HTML entrypoint, JS bundles, and the worker script.
    ///
    /// NOTE: Static resources (especially the `Worker`) must be loaded from the same origin
    /// as the JavaScript that instantiates them. Loading them via `file://` would break
    /// same-origin checks and cause CORS / security failures.
    ///
    /// By serving all assets through `translations://app/`, we ensure a consistent
    /// same-origin environment inside the WebView.
    private static let defaultRouter: TinyRouter = {
        TinyRouter()
            .register("models-buffer", ModelsBufferRoute())
            .register("models", ModelsRoute())
            .register("translator", TranslatorRoute())
            .setDefault(StaticFileRoute())
    }()

    private let router: TinyRouter
    private let logger: Logger
    private var requestTasks = [ObjectIdentifier: Task<Void, Never>]()

    init(router: TinyRouter = TranslationsSchemeHandler.defaultRouter, logger: Logger = DefaultLogger.shared) {
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
                // Delegate everything for this host to TinyRouter.
                let reply = try await router.route(url)
                try Task.checkCancellation()
                try send(reply, for: url, to: urlSchemeTask)
            } catch is CancellationError {
                self.logger.log("Scheme task cancelled.",
                                level: .debug,
                                category: .translations)
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
        // The route response should provide a valid HTTPURLResponse.
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

        // Only accept the custom scheme.
        guard url.scheme == Self.scheme else {
            throw TinyRouterError.unsupportedScheme(expected: Self.scheme, found: url.scheme)
        }

        // Only accept the expected host.
        guard url.host == Self.host else {
            throw TinyRouterError.unsupportedHost(expected: Self.host, found: url.host)
        }

        return url
    }
}
